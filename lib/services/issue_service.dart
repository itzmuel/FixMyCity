import 'package:uuid/uuid.dart';
import '../models/issue.dart';
import '../models/report_draft.dart';
import 'local_storage_service.dart';

class IssueService {
  IssueService(this._storage);

  final LocalStorageService _storage;

  /// Create a new issue from the report draft and persist it
  Future<Issue> submitReport(ReportDraft draft) async {
    final now = DateTime.now();
    final id = 'FM-${const Uuid().v4().substring(0, 8).toUpperCase()}';

    final issue = Issue(
      id: id,
      category: draft.category!,
      description: draft.description!,
      createdAt: now,
      status: IssueStatus.submitted,
      address: draft.address,
      latitude: draft.latitude,
      longitude: draft.longitude,
      photoPath: draft.photoPath,
    );

    final issues = await _storage.loadIssues();
    issues.insert(0, issue); // newest first
    await _storage.saveIssues(issues);

    return issue;
  }

  Future<List<Issue>> getMyReports() async {
    return _storage.loadIssues();
  }

  /// Delete ONLY the selected issues by id
  Future<void> deleteByIds(Set<String> ids) async {
    if (ids.isEmpty) return;

    final issues = await _storage.loadIssues();
    final updated = issues.where((i) => !ids.contains(i.id)).toList();
    await _storage.saveIssues(updated);
  }

  /// Delete a single issue
  Future<void> deleteById(String id) async {
    await deleteByIds({id});
  }

  Future<void> clearAll() async {
    await _storage.clearIssues();
  }
}

/// Simple singleton-like access (easy for capstone)
final issueService = IssueService(LocalStorageService());
