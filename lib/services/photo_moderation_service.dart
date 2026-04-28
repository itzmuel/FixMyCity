import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/report_draft.dart';
import 'upload_validation.dart';

enum PhotoModerationSource {
  server,
  localFallback,
}

class PhotoModerationDecision {
  final bool allowed;
  final PhotoModerationSource source;
  final String? reason;
  final String? reasonCode;
  final double? score;

  const PhotoModerationDecision.allow({
    required this.source,
    this.score,
  }) : allowed = true,
       reason = null,
       reasonCode = null;

  const PhotoModerationDecision.deny({
    required this.source,
    required this.reason,
    this.reasonCode,
    this.score,
  }) : allowed = false;
}

class PhotoModerationService {
  static const String _functionName = String.fromEnvironment(
    'SUPABASE_PHOTO_MODERATION_FUNCTION',
    defaultValue: 'moderate-report-photo',
  );

  SupabaseClient get _client => Supabase.instance.client;

  Future<PhotoModerationDecision> moderateBeforeSubmit(
    ReportDraft draft,
  ) async {
    final path = draft.photoPath;
    if (path == null || path.trim().isEmpty) {
      return const PhotoModerationDecision.allow(
        source: PhotoModerationSource.localFallback,
      );
    }

    final localResult = await validateIssuePhoto(
      path,
      category: draft.category,
      description: draft.description,
    );
    if (!localResult.valid) {
      return PhotoModerationDecision.deny(
        source: PhotoModerationSource.localFallback,
        reason:
            localResult.error ?? 'Photo did not pass pre-submission checks.',
        reasonCode: localResult.code?.name,
        score: localResult.score,
      );
    }

    try {
      final payload = await _buildModerationPayload(draft);
      final response = await _client.functions.invoke(
        _functionName,
        body: payload,
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const PhotoModerationDecision.allow(
          source: PhotoModerationSource.localFallback,
        );
      }

      final allow = data['allow'] == true || data['blocked'] == false;
      final score = (data['score'] as num?)?.toDouble();
      final reason = (data['reason'] as String?)?.trim();
      final reasonCode = (data['reasonCode'] as String?)?.trim();

      if (!allow) {
        return PhotoModerationDecision.deny(
          source: PhotoModerationSource.server,
          reason:
              reason?.isNotEmpty == true
                  ? reason!
                  : 'This photo was rejected by content moderation.',
          reasonCode: reasonCode,
          score: score,
        );
      }

      return PhotoModerationDecision.allow(
        source: PhotoModerationSource.server,
        score: score,
      );
    } catch (_) {
      return const PhotoModerationDecision.allow(
        source: PhotoModerationSource.localFallback,
      );
    }
  }

  Future<Map<String, dynamic>> _buildModerationPayload(ReportDraft draft) async {
    final path = draft.photoPath;
    final payload = <String, dynamic>{
      'category': draft.category?.name,
      'description': draft.description,
      'address': draft.address,
      'latitude': draft.latitude,
      'longitude': draft.longitude,
      'threshold': 0.65,
    };

    if (path == null || path.trim().isEmpty) return payload;
    if (_isRemoteUrl(path)) {
      payload['photoUrl'] = path;
      return payload;
    }

    final file = File(path);
    if (!await file.exists()) return payload;

    final bytes = await file.readAsBytes();
    payload['mimeType'] = _mimeTypeFromPath(path);
    payload['imageBase64'] = base64Encode(bytes);
    return payload;
  }

  bool _isRemoteUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}

final photoModerationService = PhotoModerationService();