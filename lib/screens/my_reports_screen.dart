import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../app/refresh_bus.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import 'report/report_details_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<Issue>> _future;

  int _lastTick = 0;

  bool _selectMode = false;
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = issueService.getMyReports();

    _lastTick = refreshBus.myReportsTick;
    refreshBus.addListener(_onBusPing);
  }

  void _onBusPing() {
    if (!mounted) return;
    if (refreshBus.myReportsTick != _lastTick) {
      _lastTick = refreshBus.myReportsTick;
      _refresh();
    }
  }

  @override
  void dispose() {
    refreshBus.removeListener(_onBusPing);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = issueService.getMyReports();
    });
    await _future;
  }

  void _toggleSelectionMode([bool? value]) {
    setState(() {
      _selectMode = value ?? !_selectMode;
      if (!_selectMode) _selectedIds.clear();
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reports?'),
        content: Text('Are you sure you want to delete $count selected report(s)? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await issueService.deleteByIds(_selectedIds);

    // refresh UI
    if (!mounted) return;
    refreshBus.pingHome();      // stats on home update too
    refreshBus.pingMyReports(); // and this list
    _toggleSelectionMode(false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted $count report(s).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectMode ? 'Select Reports' : 'My Reports'),
        actions: [
          if (_selectMode) ...[
            IconButton(
              onPressed: selectedCount == 0 ? null : _confirmDeleteSelected,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete selected',
            ),
            IconButton(
              onPressed: () => _toggleSelectionMode(false),
              icon: const Icon(Icons.close),
              tooltip: 'Cancel selection',
            ),
          ] else ...[
            TextButton(
              onPressed: () => _toggleSelectionMode(true),
              child: const Text('Select'),
            ),
          ],
        ],
      ),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snap) {
          final issues = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting && issues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (issues.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox, size: 36, color: AppColors.muted),
                        SizedBox(height: 10),
                        Text('No reports yet', style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 6),
                        Text('Your submitted issues will appear here.',
                            style: TextStyle(color: AppColors.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final issue = issues[i];
                final isSelected = _selectedIds.contains(issue.id);

                return Card(
                  child: ListTile(
                    leading: _selectMode
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelected(issue.id),
                          )
                        : null,
                    title: Text(
                      issue.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      issue.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    trailing: _selectMode
                        ? null
                        : _StatusChip(status: issue.status),
                    onLongPress: () {
                      if (!_selectMode) {
                        _toggleSelectionMode(true);
                        _toggleSelected(issue.id);
                      }
                    },
                    onTap: () {
                      if (_selectMode) {
                        _toggleSelected(issue.id);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReportDetailsScreen(issue: issue),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _selectMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: FilledButton.icon(
                  onPressed: selectedCount == 0 ? null : _confirmDeleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(selectedCount == 0
                      ? 'Select reports to delete'
                      : 'Delete selected ($selectedCount)'),
                ),
              ),
            )
          : null,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IssueStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;

    switch (status) {
      case IssueStatus.submitted:
        label = 'Submitted';
        bg = const Color(0xFFFFF3C7);
        fg = const Color(0xFF8A5A00);
        break;
      case IssueStatus.inProgress:
        label = 'In Progress';
        bg = const Color(0xFFD9ECFF);
        fg = const Color(0xFF0B4A8B);
        break;
      case IssueStatus.resolved:
        label = 'Resolved';
        bg = const Color(0xFFDFF7E8);
        fg = const Color(0xFF0B6B2A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withValues(alpha: 0.6)), // 60%
      ),
      child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
