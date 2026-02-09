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
}
