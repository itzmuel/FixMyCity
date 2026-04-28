import 'issue_category.dart';

enum IssueStatus {
  submitted,
  inProgress,
  resolved,
}

class Issue {
  final String id;
  final IssueCategory category;
  final String description;
  final DateTime createdAt;
  final IssueStatus status;

  final String? address;
  final double? latitude;
  final double? longitude;
  final String? photoPath;

  Issue({
    required this.id,
    required this.category,
    required this.description,
    required this.createdAt,
    this.status = IssueStatus.submitted,
    this.address,
    this.latitude,
    this.longitude,
    this.photoPath,
  });

  // Convert Flutter enum → Supabase enum
  String get _statusToDb {
    switch (status) {
      case IssueStatus.submitted:
        return 'submitted';
      case IssueStatus.inProgress:
        return 'in_progress';
      case IssueStatus.resolved:
        return 'resolved';
    }
  }

  Map<String, dynamic> toSupabaseRow(String reporterId) {
    return {
      'id': id,
      'reporter_id': reporterId, // REQUIRED by RLS
      'category': category.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': _statusToDb,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoPath,
    };
  }

  // Convert Supabase enum → Flutter enum
  static IssueStatus _statusFromDb(String value) {
    switch (value.trim().toLowerCase()) {
      case 'submitted':
        return IssueStatus.submitted;
      case 'in_progress':
        return IssueStatus.inProgress;
      case 'resolved':
        return IssueStatus.resolved;
      default:
        return IssueStatus.submitted;
    }
  }

  static IssueCategory _categoryFromDb(dynamic rawValue) {
    final raw = (rawValue ?? '').toString().trim();
    if (raw.isEmpty) return IssueCategory.other;

    final normalized = raw.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

    for (final category in IssueCategory.values) {
      if (category.name == normalized) return category;
    }

    if (normalized.contains('pothole')) return IssueCategory.pothole;
    if (normalized.contains('street') && normalized.contains('light')) {
      return IssueCategory.streetlight;
    }
    if (normalized.contains('graffiti')) return IssueCategory.graffiti;
    if (normalized.contains('sidewalk')) return IssueCategory.sidewalk;
    if (normalized.contains('dump')) return IssueCategory.dumping;

    return IssueCategory.other;
  }

  static DateTime _createdAtFromDb(dynamic rawValue) {
    if (rawValue is DateTime) return rawValue;
    final parsed = DateTime.tryParse((rawValue ?? '').toString());
    return parsed ?? DateTime.now();
  }

  factory Issue.fromSupabaseRow(Map<String, dynamic> row) {
    final rawStatus = (row['status'] ?? 'submitted').toString();
    return Issue(
      id: (row['id'] ?? '').toString(),
      category: _categoryFromDb(row['category']),
      description: (row['description'] ?? '').toString(),
      createdAt: _createdAtFromDb(row['created_at']),
      status: _statusFromDb(rawStatus),
      address: row['address'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      photoPath: (row['photo_url'] ?? row['photo_path']) as String?,
    );
  }
}