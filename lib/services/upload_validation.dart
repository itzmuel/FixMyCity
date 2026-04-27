import 'dart:io';

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

  const PhotoValidationResult.ok() : valid = true, error = null;

  const PhotoValidationResult.fail(String message)
      : valid = false,
        error = message;
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
}) async {
  // Extension check.
  if (!_isAllowedExtension(path)) {
    // Fall back to MIME type when extension is ambiguous.
    if (mimeType == null || !_isAllowedMimeType(mimeType)) {
      return const PhotoValidationResult.fail(
        'Unsupported file type. Please use JPG, PNG, or WEBP.',
      );
    }
  }

  // MIME type check (when available).
  if (mimeType != null && !_isAllowedMimeType(mimeType)) {
    return const PhotoValidationResult.fail(
      'Unsupported file type. Please use JPG, PNG, or WEBP.',
    );
  }

  // Size check.
  final file = File(path);
  if (await file.exists()) {
    final size = await file.length();
    if (size > issuePhotoMaxBytes) {
      return const PhotoValidationResult.fail(
        'Photo is too large. Maximum allowed size is 5 MB.',
      );
    }
  }

  return const PhotoValidationResult.ok();
}
