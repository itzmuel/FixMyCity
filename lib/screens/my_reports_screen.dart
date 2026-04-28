import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../app/refresh_bus.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import '../widgets/fmc_status_chip.dart';
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
            final isAuthError = snap.error is IssueAuthRequiredException;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isAuthError ? Icons.lock_outline : Icons.cloud_off,
                        size: 36,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isAuthError ? 'You need to sign in' : 'Could not load reports',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAuthError
                            ? 'Your session expired or is missing. Please sign in again to view reports.'
                            : 'We could not fetch your reports right now. Check your connection and try again.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      if (isAuthError)
                        FilledButton(
                          onPressed: () => context.go('/auth'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Go to Sign in'),
                        )
                      else
                        FilledButton(
                          onPressed: () => _refresh(),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Try again'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (issues.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.inbox, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 10),
                      Text('No reports yet', style: TextStyle(fontWeight: FontWeight.w800)),
                      SizedBox(height: 6),
                      Text('Your submitted issues will appear here.',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
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

                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppShadows.cardSoft,
                  ),
                  child: ListTile(
                    title: Text(
                      issue.category.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      issue.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: FmcStatusChip(status: issue.status),
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
