// ignore_for_file: avoid_print

import 'dart:io';

import 'package:image/image.dart' as img;

import '../models/issue_category.dart';
import 'upload_validation.dart';

/// Debug/analysis tool for tuning photo validation thresholds.
/// Use this to analyze rejection patterns and optimize scoring.
class PhotoValidationTuningReport {
  final String filePath;
  final IssueCategory? category;
  final String? description;
  final PhotoValidationResult validationResult;
  final PhotoValidationProfile? profile;
  final double? relevanceScore;
  final Map<String, double> componentScores;

  PhotoValidationTuningReport({
    required this.filePath,
    required this.category,
    required this.description,
    required this.validationResult,
    this.profile,
    this.relevanceScore,
    required this.componentScores,
  });

  /// Print human-readable analysis for debugging.
  void printAnalysis() {
    print('=== Photo Validation Tuning Report ===');
    print('File: $filePath');
    print('Category: ${category?.label ?? "none"}');
    print('Description: ${description ?? "none"}');
    print('Valid: ${validationResult.valid}');
    print('Error: ${validationResult.error ?? "none"}');
    print('Code: ${validationResult.code?.name ?? "none"}');
    print('Score: ${validationResult.score}');
    print('');

    if (profile != null) {
      print('--- Image Profile ---');
      print('Edge Density: ${profile!.edgeDensity.toStringAsFixed(4)}');
      print('Luminance Variance: ${profile!.luminanceVariance.toStringAsFixed(2)}');
      print('Mean Saturation: ${profile!.meanSaturation.toStringAsFixed(4)}');
      print('');
    }

    if (componentScores.isNotEmpty) {
      print('--- Component Scores ---');
      componentScores.forEach((key, value) {
        print('$key: ${value.toStringAsFixed(4)}');
      });
      print('Relevance Score: ${relevanceScore?.toStringAsFixed(4) ?? "N/A"}');
      print('');
    }

    print('Recommendation: ${validationResult.valid ? "ACCEPT" : "REJECT"}');
    print('====================================');
  }

  /// Export as JSON for logging/analysis.
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'category': category?.name,
      'description': description,
      'valid': validationResult.valid,
      'error': validationResult.error,
      'code': validationResult.code?.name,
      'score': validationResult.score,
      'profile': profile != null
          ? {
              'edgeDensity': profile!.edgeDensity,
              'luminanceVariance': profile!.luminanceVariance,
              'meanSaturation': profile!.meanSaturation,
            }
          : null,
      'relevanceScore': relevanceScore,
      'componentScores': componentScores,
    };
  }
}

class PhotoValidationProfile {
  final double edgeDensity;
  final double luminanceVariance;
  final double meanSaturation;
  final double brightness;
  final double blurScore;

  const PhotoValidationProfile({
    required this.edgeDensity,
    required this.luminanceVariance,
    required this.meanSaturation,
    required this.brightness,
    required this.blurScore,
  });
}

/// Detailed tuning analysis without blocking—for calibration use only.
Future<PhotoValidationTuningReport> analyzePhotoForTuning(
  String path, {
  IssueCategory? category,
  String? description,
}) async {
  final validationResult = await validateIssuePhoto(
    path,
    category: category,
    description: description,
  );

  final components = <String, double>{};
  PhotoValidationProfile? profile;
  double? relevanceScore;

  try {
    final bytes = await File(path).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded != null) {
      final sample = _downsample(decoded, maxEdge: 240);

      final brightness = _meanLuma(sample);
      components['brightness'] = brightness;

      final blurScore = _varianceOfLaplacian(sample);
      components['blurScore'] = blurScore;

      final imageProfile = _buildImageProfile(sample);
      profile = PhotoValidationProfile(
        edgeDensity: imageProfile.edgeDensity,
        luminanceVariance: imageProfile.luminanceVariance,
        meanSaturation: imageProfile.meanSaturation,
        brightness: brightness,
        blurScore: blurScore,
      );

      components['edgeDensity'] = imageProfile.edgeDensity;
      components['luminanceVariance'] = imageProfile.luminanceVariance;
      components['meanSaturation'] = imageProfile.meanSaturation;

      relevanceScore = _estimateRelevanceScore(
        profile: imageProfile,
        category: category,
        description: description,
      );
      components['relevanceScore'] = relevanceScore;
    }
  } catch (_) {
    // Keep analysis resilient
  }

  return PhotoValidationTuningReport(
    filePath: path,
    category: category,
    description: description,
    validationResult: validationResult,
    profile: profile,
    relevanceScore: relevanceScore,
    componentScores: components,
  );
}

// Copy of internal functions from upload_validation.dart for tuning.
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
