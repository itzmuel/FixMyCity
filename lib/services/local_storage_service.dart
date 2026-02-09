import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/issue.dart';
import '../models/issue_category.dart';

class LocalStorageService {
  static const _keyReports = 'fixmycity_reports_v1';

  /// Save list of issues to device storage
  Future<void> saveIssues(List<Issue> issues) async {
    final prefs = await SharedPreferences.getInstance();
    final data = issues.map(_issueToJson).toList();
    await prefs.setString(_keyReports, jsonEncode(data));
  }

  /// Load list of issues from device storage
  Future<List<Issue>> loadIssues() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyReports);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => _issueFromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Clear stored issues
  Future<void> clearIssues() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReports);
  }

  // ---- Helpers ----

  Map<String, dynamic> _issueToJson(Issue i) {
    return {
      'id': i.id,
      'category': i.category.name,
      'description': i.description,
      'createdAt': i.createdAt.toIso8601String(),
      // Optional fields (if you later add them)
      'status': i.status.name,
      'address': i.address,
      'latitude': i.latitude,
      'longitude': i.longitude,
      'photoPath': i.photoPath,
    };
  }

  Issue _issueFromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as String,
      category: IssueCategory.values.firstWhere((c) => c.name == json['category']),
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: IssueStatus.values.firstWhere((s) => s.name == (json['status'] ?? 'submitted')),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      photoPath: json['photoPath'] as String?,
    );
  }
}
