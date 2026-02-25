import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/issue.dart';
import '../models/report_draft.dart';

class IssueService {
  static const String _photosBucket = String.fromEnvironment(
    'SUPABASE_PHOTOS_BUCKET',
    defaultValue: 'issue-photos',
  );

  SupabaseClient get _client => Supabase.instance.client;

  /// Create a new issue from the report draft and persist it
  Future<Issue> submitReport(ReportDraft draft) async {
    await _ensureSignedIn();
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('You must be signed in to submit a report.');
    }

    final now = DateTime.now();
    final id = 'FM-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    String? uploadedPhotoPath;
    try {
      uploadedPhotoPath = await _uploadPhotoIfNeeded(issueId: id, localPath: draft.photoPath);
    } on StorageException catch (e) {
      if (!_isStorageAuthorizationError(e)) rethrow;
      uploadedPhotoPath = null;
    }

    final issue = Issue(
      id: id,
      category: draft.category!,
      description: draft.description!,
      createdAt: now,
      status: IssueStatus.submitted,
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      photoPath: uploadedPhotoPath,
    );

    final row = issue.toSupabaseRow();
    row['reporter_id'] = userId;
    try {
      await _client.from('issues').insert(row);
    } on PostgrestException catch (e) {
      if (!_isMissingPhotoColumnError(e)) rethrow;

      final fallbackRow = Map<String, dynamic>.from(row);
      if (fallbackRow.containsKey('photo_url')) {
        final photoValue = fallbackRow.remove('photo_url');
        fallbackRow['photo_path'] = photoValue;
      } else if (fallbackRow.containsKey('photo_path')) {
        final photoValue = fallbackRow.remove('photo_path');
        fallbackRow['photo_url'] = photoValue;
      }
      await _client.from('issues').insert(fallbackRow);
    }
    return issue;
  }

  Future<List<Issue>> getMyReports() async {
    await _ensureSignedIn();
    final rows = await _client.from('issues').select().order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((row) => Issue.fromSupabaseRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Delete ONLY the selected issues by id
  Future<void> deleteByIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    throw UnsupportedError('Deleting issues is not allowed by the current database policies.');
  }

  /// Delete a single issue
  Future<void> deleteById(String id) async {
    await deleteByIds({id});
  }

  Future<void> clearAll() async {
    throw UnsupportedError('Deleting issues is not allowed by the current database policies.');
  }

  Future<String?> _uploadPhotoIfNeeded({
    required String issueId,
    required String? localPath,
  }) async {
    if (localPath == null || localPath.trim().isEmpty) return null;
    if (_isRemoteUrl(localPath)) return localPath;

    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Selected photo file was not found: $localPath');
    }

    await _ensureSignedIn();
    final userId = _client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('You must be signed in to upload a photo.');
    }

    final ext = _fileExtension(localPath);
    final objectPath = 'users/$userId/${issueId}_${DateTime.now().millisecondsSinceEpoch}$ext';

    await _client.storage.from(_photosBucket).upload(
          objectPath,
          file,
          fileOptions: const FileOptions(upsert: false),
        );

    return objectPath;
  }

  bool _isRemoteUrl(String value) {
    final v = value.toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  Future<void> _ensureSignedIn() async {
    if (_client.auth.currentSession != null) return;
    throw StateError('You must sign in to use this feature.');
  }

  bool _isStorageAuthorizationError(StorageException e) {
    final code = '${e.statusCode}'.trim();
    if (code == '401' || code == '403') return true;

    final message = e.message.toLowerCase();
    return message.contains('row-level security') || message.contains('unauthorized');
  }

  bool _isMissingPhotoColumnError(PostgrestException e) {
    final code = (e.code ?? '').trim();
    final message = e.message.toLowerCase();
    return code == 'PGRST204' &&
        (message.contains("'photo_path' column") || message.contains("'photo_url' column"));
  }

  String _fileExtension(String path) {
    final slashIndex = path.lastIndexOf(RegExp(r'[\\/]'));
    final fileName = slashIndex >= 0 ? path.substring(slashIndex + 1) : path;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == fileName.length - 1) return '.jpg';
    return fileName.substring(dotIndex);
  }
}

/// Simple singleton-like access (easy for capstone)
final issueService = IssueService();