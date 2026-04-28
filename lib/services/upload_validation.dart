import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

import '../models/issue_category.dart';

/// Maximum allowed photo size in bytes (5 MB).
const int issuePhotoMaxBytes = 5 * 1024 * 1024;

const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

const Set<String> _allowedMimeTypes = {
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
};

/// Result of a photo validation check.
class PhotoValidationResult {
  final bool valid;
  final String? error;
  final PhotoValidationCode? code;
  final double? score;

  const PhotoValidationResult.ok()
    : valid = true,
      error = null,
      code = null,
      score = null;

  const PhotoValidationResult.fail(this.error, {this.code, this.score})
      : valid = false,
        assert(error != null);
}

enum PhotoValidationCode {
  unsupportedType,
  fileTooLarge,
  unreadableImage,
  containsFace,
  tooDark,
  tooBright,
  tooBlurry,
  notCivicRelevant,
}

class IssuePhotoValidationException implements Exception {
  final String message;
  final PhotoValidationCode? code;

  const IssuePhotoValidationException(this.message, {this.code});

  @override
  String toString() => message;
}

String _ext(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0 || dot >= path.length - 1) return '';
  return path.substring(dot + 1).toLowerCase();
}

bool _isAllowedExtension(String path) =>
    _allowedExtensions.contains(_ext(path));

bool _isAllowedMimeType(String mimeType) =>
    _allowedMimeTypes.contains(mimeType.toLowerCase());

/// Validates a picked photo file before saving / uploading.
///
/// [path] is the local file path.
/// [mimeType] is the optional MIME type reported by the picker.
///
/// Rules (must match admin dashboard storage policy):
///   • Extension must be jpg/jpeg/png/webp.
///   • MIME type (when provided) must be image/jpeg, image/jpg, image/png, or image/webp.
///   • File size must not exceed 5 MB.
Future<PhotoValidationResult> validateIssuePhoto(
  String path, {
  String? mimeType,
  IssueCategory? category,
  String? description,
}) async {
  // Extension check.
  if (!_isAllowedExtension(path)) {
    // Fall back to MIME type when extension is ambiguous.
    if (mimeType == null || !_isAllowedMimeType(mimeType)) {
      return const PhotoValidationResult.fail(
        'Unsupported file type. Please use JPG, PNG, or WEBP.',
        code: PhotoValidationCode.unsupportedType,
      );
    }
  }

  // MIME type check (when available).
  if (mimeType != null && !_isAllowedMimeType(mimeType)) {
    return const PhotoValidationResult.fail(
      'Unsupported file type. Please use JPG, PNG, or WEBP.',
      code: PhotoValidationCode.unsupportedType,
    );
  }

  // Size check.
  final file = File(path);
  if (await file.exists()) {
    final size = await file.length();
    if (size > issuePhotoMaxBytes) {
      return const PhotoValidationResult.fail(
        'Photo is too large. Maximum allowed size is 5 MB.',
        code: PhotoValidationCode.fileTooLarge,
      );
    }
  }

  final faceCheck = await _detectFace(path);
  if (!faceCheck.valid) return faceCheck;

  final qualityCheck = await _checkImageQuality(path);
  if (!qualityCheck.valid) return qualityCheck;

  final relevanceCheck = await _checkLocalRelevance(
    path,
    category: category,
    description: description,
  );
  if (!relevanceCheck.valid) return relevanceCheck;

  return const PhotoValidationResult.ok();
}

Future<PhotoValidationResult> _detectFace(String path) async {
  final options = FaceDetectorOptions(
    enableContours: false,
    enableLandmarks: false,
    performanceMode: FaceDetectorMode.fast,
  );
  final detector = FaceDetector(options: options);

  try {
    final image = InputImage.fromFilePath(path);
    final faces = await detector.processImage(image);
    if (faces.isNotEmpty) {
      return const PhotoValidationResult.fail(
        'This photo appears to contain a face. Please capture the civic issue only.',
        code: PhotoValidationCode.containsFace,
      );
    }
    return const PhotoValidationResult.ok();
  } catch (_) {
    // If detector fails on an image format edge case, keep flow resilient.
    return const PhotoValidationResult.ok();
  } finally {
    await detector.close();
  }
}

Future<PhotoValidationResult> _checkImageQuality(String path) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);

  if (decoded == null) {
    return const PhotoValidationResult.fail(
      'We could not read this image. Please retake the photo.',
      code: PhotoValidationCode.unreadableImage,
    );
  }

  final sample = _downsample(decoded, maxEdge: 300);
  final brightness = _meanLuma(sample);
  if (brightness < 35) {
    return const PhotoValidationResult.fail(
      'Photo is too dark. Please retake it with better lighting.',
      code: PhotoValidationCode.tooDark,
    );
  }
  if (brightness > 225) {
    return const PhotoValidationResult.fail(
      'Photo is too bright. Please avoid strong glare and retake.',
      code: PhotoValidationCode.tooBright,
    );
  }

  final blurScore = _varianceOfLaplacian(sample);
  if (blurScore < 90) {
    return const PhotoValidationResult.fail(
      'Photo looks blurry. Please focus on the issue and retake.',
      code: PhotoValidationCode.tooBlurry,
    );
  }

  return const PhotoValidationResult.ok();
}

Future<PhotoValidationResult> _checkLocalRelevance(
  String path, {
  IssueCategory? category,
  String? description,
}) async {
  final bytes = await File(path).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return const PhotoValidationResult.ok();
  }

  final sample = _downsample(decoded, maxEdge: 240);
  final profile = _buildImageProfile(sample);
  final score = _estimateRelevanceScore(
    profile: profile,
    category: category,
    description: description,
  );

  if (score < 0.30) {
    return PhotoValidationResult.fail(
      'We could not detect a clear civic issue in this photo. Please retake and focus on the problem area.',
      code: PhotoValidationCode.notCivicRelevant,
      score: score,
    );
  }

  return PhotoValidationResult.ok();
}

class _ImageProfile {
  final double edgeDensity;
  final double luminanceVariance;
  final double meanSaturation;

  const _ImageProfile({
    required this.edgeDensity,
    required this.luminanceVariance,
    required this.meanSaturation,
  });
}

_ImageProfile _buildImageProfile(img.Image image) {
  var edgeCount = 0;
  var saturationSum = 0.0;
  var lumaSum = 0.0;
  var lumaSqSum = 0.0;
  final total = image.width * image.height;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();

      final maxValue = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minValue = r < g ? (r < b ? r : b) : (g < b ? g : b);
      final saturation = maxValue <= 0 ? 0.0 : (maxValue - minValue) / maxValue;
      saturationSum += saturation;

      final luma = 0.299 * r + 0.587 * g + 0.114 * b;
      lumaSum += luma;
      lumaSqSum += luma * luma;

      if (x > 0 && y > 0) {
        final left = image.getPixel(x - 1, y);
        final up = image.getPixel(x, y - 1);
        final lumaLeft = 0.299 * left.r + 0.587 * left.g + 0.114 * left.b;
        final lumaUp = 0.299 * up.r + 0.587 * up.g + 0.114 * up.b;
        final gradient = (luma - lumaLeft).abs() + (luma - lumaUp).abs();
        if (gradient > 40) edgeCount++;
      }
    }
  }

  final meanLuma = total == 0 ? 0.0 : lumaSum / total;
  final luminanceVariance = total == 0 ? 0.0 : (lumaSqSum / total) - (meanLuma * meanLuma);
  final edgeDensity = total == 0 ? 0.0 : edgeCount / total;
  final meanSaturation = total == 0 ? 0.0 : saturationSum / total;

  return _ImageProfile(
    edgeDensity: edgeDensity,
    luminanceVariance: luminanceVariance,
    meanSaturation: meanSaturation,
  );
}

double _estimateRelevanceScore({
  required _ImageProfile profile,
  IssueCategory? category,
  String? description,
}) {
  var score = 0.5;

  if (profile.edgeDensity >= 0.025 && profile.edgeDensity <= 0.45) {
    score += 0.16;
  } else if (profile.edgeDensity < 0.015) {
    score -= 0.20;
  } else {
    score -= 0.08;
  }

  if (profile.luminanceVariance >= 320) {
    score += 0.14;
  } else {
    score -= 0.12;
  }

  if (profile.meanSaturation >= 0.08) {
    score += 0.07;
  }

  final trimmedDescription = description?.toLowerCase().trim() ?? '';
  if (trimmedDescription.length >= 16) {
    score += 0.06;
  }

  if (category != null && trimmedDescription.isNotEmpty) {
    final keywords = _categoryKeywords(category);
    if (keywords.any(trimmedDescription.contains)) {
      score += 0.10;
    }
  }

  if (category == IssueCategory.other) {
    score -= 0.04;
  }

  return score.clamp(0.0, 1.0);
}

List<String> _categoryKeywords(IssueCategory category) {
  switch (category) {
    case IssueCategory.pothole:
      return const <String>['pothole', 'road', 'asphalt', 'crack'];
    case IssueCategory.streetlight:
      return const <String>['streetlight', 'light', 'lamp', 'pole', 'dark'];
    case IssueCategory.graffiti:
      return const <String>['graffiti', 'paint', 'wall', 'vandal'];
    case IssueCategory.sidewalk:
      return const <String>['sidewalk', 'curb', 'walkway', 'pavement'];
    case IssueCategory.dumping:
      return const <String>['garbage', 'trash', 'dump', 'waste', 'litter'];
    case IssueCategory.other:
      return const <String>['issue', 'problem', 'hazard'];
  }
}

img.Image _downsample(img.Image source, {required int maxEdge}) {
  final width = source.width;
  final height = source.height;
  final longer = width > height ? width : height;
  if (longer <= maxEdge) return source;

  final scale = maxEdge / longer;
  final targetW = (width * scale).round().clamp(1, width);
  final targetH = (height * scale).round().clamp(1, height);

  return img.copyResize(source, width: targetW, height: targetH);
}

double _meanLuma(img.Image image) {
  var sum = 0.0;
  final total = image.width * image.height;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toDouble();
      final g = pixel.g.toDouble();
      final b = pixel.b.toDouble();
      sum += 0.299 * r + 0.587 * g + 0.114 * b;
    }
  }

  return total == 0 ? 0 : sum / total;
}

double _varianceOfLaplacian(img.Image image) {
  final kernel = <List<int>>[
    <int>[0, 1, 0],
    <int>[1, -4, 1],
    <int>[0, 1, 0],
  ];

  final values = <double>[];
  for (var y = 1; y < image.height - 1; y++) {
    for (var x = 1; x < image.width - 1; x++) {
      var lap = 0.0;
      for (var ky = -1; ky <= 1; ky++) {
        for (var kx = -1; kx <= 1; kx++) {
          final pixel = image.getPixel(x + kx, y + ky);
          final gray = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
          lap += gray * kernel[ky + 1][kx + 1];
        }
      }
      values.add(lap);
    }
  }

  if (values.isEmpty) return 0;
  final mean = values.reduce((a, b) => a + b) / values.length;
  var variance = 0.0;
  for (final v in values) {
    final d = v - mean;
    variance += d * d;
  }
  return variance / values.length;
}
