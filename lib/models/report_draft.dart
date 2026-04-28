import 'issue_category.dart';

class ReportDraft {
  IssueCategory? category;

  double? latitude;
  double? longitude;
  String? address;

  String? description;

  String? photoPath; // local file path

  bool get isStep1Valid => category != null;
  bool get isStep2Valid => latitude != null && longitude != null;
  bool get isStep3Valid =>
      description != null && description!.trim().isNotEmpty;
  bool get isStep4Valid => photoPath != null && photoPath!.trim().isNotEmpty;

  bool get isReadyToSubmit =>
      isStep1Valid && isStep2Valid && isStep3Valid && isStep4Valid;
}
