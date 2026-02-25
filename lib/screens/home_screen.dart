import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import '../widgets/stat_tile.dart';
import 'report/report_details_screen.dart';
import '../app/route_observer.dart';
import '../app/refresh_bus.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late Future<List<Issue>> _future;

  @override
  void initState() {
    super.initState();
    _future = issueService.getMyReports();

    // ✅ Listen for tab re-select / tab navigation pings
    refreshBus.addListener(_onRefreshPing);
  }

  void _onRefreshPing() {
    if (!mounted) return;
    _refresh();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // ✅ remove listener
    refreshBus.removeListener(_onRefreshPing);

    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    if (!mounted) return;
    _refresh();
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
      appBar: AppBar(title: const Text('FixMyCity')),
      body: FutureBuilder<List<Issue>>(
        future: _future,
        builder: (context, snap) {
          final issues = snap.data ?? [];

          final submitted =
              issues.where((i) => i.status == IssueStatus.submitted).length;
          final inProgress =
              issues.where((i) => i.status == IssueStatus.inProgress).length;
          final resolved =
              issues.where((i) => i.status == IssueStatus.resolved).length;

          final recent = issues.take(3).toList();

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
                          'Your session expired or is missing. Please sign in again to continue.',
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

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10), // 10%
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.campaign,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Make Your City Better',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Report issues in your neighborhood and help keep the community safe and clean.',
                          style: TextStyle(color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => context.go('/report'),
                            child: const Text('Report an Issue'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Community Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(child: StatTile(title: 'Submitted', value: '$submitted')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(title: 'In Progress', value: '$inProgress')),
                    const SizedBox(width: 10),
                    Expanded(child: StatTile(title: 'Resolved', value: '$resolved')),
                  ],
                ),

                const SizedBox(height: 18),

                const Text(
                  'Recent Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),

                if (recent.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: const [
                          Icon(Icons.description, size: 36, color: AppColors.muted),
                          SizedBox(height: 10),
                          Text('No reports yet', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 6),
                          Text('Be the first to report an issue!',
                              style: TextStyle(color: AppColors.muted)),
                        ],
                      ),
                    ),
                  )
                else
                  ...recent.map(
                    (issue) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
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
                      ),
                    ),
                  ),
              ],
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
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
