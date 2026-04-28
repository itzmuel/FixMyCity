import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/issue_category.dart';

class ReportModerationAnalyticsService {
  static const String _tableName = 'report_moderation_events';

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> logModerationEvent({
    required String eventType,
    required bool allowed,
    required String source,
    String? issueId,
    IssueCategory? category,
    String? reasonCode,
    String? reasonMessage,
    double? score,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    final row = <String, dynamic>{
      'reporter_id': userId,
      'issue_id': issueId,
      'event_type': eventType,
      'decision': allowed ? 'allow' : 'deny',
      'source': source,
      'category': category?.name,
      'reason_code': reasonCode,
      'reason_message': reasonMessage,
      'score': score,
    };

    // Keep submit flow resilient if analytics table is absent in some environments.
    try {
      await _client.from(_tableName).insert(row);
    } catch (_) {}
  }
}

final reportModerationAnalyticsService = ReportModerationAnalyticsService();