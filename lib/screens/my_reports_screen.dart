import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snap) {
          final issues = snap.data ?? [];

          if (snap.connectionState == ConnectionState.waiting && issues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError && issues.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(Icons.lock_outline, size: 36, color: AppColors.muted),
                        const SizedBox(height: 10),
                        const Text('You need to sign in',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        const Text(
                          'Your session expired or is missing. Please sign in again to view reports.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => context.go('/auth'),
                          child: const Text('Go to Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
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

                return Card(
                  child: ListTile(
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
                    trailing: _StatusChip(status: issue.status),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportDetailsScreen(issue: issue),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
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
