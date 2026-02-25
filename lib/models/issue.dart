import 'issue_category.dart';

enum IssueStatus { submitted, inProgress, resolved }

class Issue {
  final String id;
  final IssueCategory category;
  final String description;
  final DateTime createdAt;

  final IssueStatus status;

  // Optional fields (useful later)
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

  Map<String, dynamic> toSupabaseRow() {
    return {
      'id': id,
      'category': category.name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status.name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'photo_url': photoPath,
    };
  }

  factory Issue.fromSupabaseRow(Map<String, dynamic> row) {
    return Issue(
      id: row['id'] as String,
      category: IssueCategory.values.firstWhere((c) => c.name == row['category']),
      description: row['description'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: IssueStatus.values.firstWhere((s) => s.name == (row['status'] ?? 'submitted')),
      address: row['address'] as String?,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      photoPath: (row['photo_url'] ?? row['photo_path']) as String?,
    );
  }
}