import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late Future<_HomeData> _future;

  static const String _sourceMunicipal =
      'https://www.kitchener.ca/en/living-in-kitchener/report-a-problem.aspx';
  static const String _sourceOntario =
      'https://www.ontario.ca/page/municipalities';

  @override
  void initState() {
    super.initState();
    _future = _loadHomeData();

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
      _future = _loadHomeData();
    });
    await _future;
  }

  Future<_HomeData> _loadHomeData() async {
    final results = await Future.wait<dynamic>([
      issueService.getCommunityIssueStats(),
      issueService.getCommunityRecentReports(limit: 3),
    ]);

    return _HomeData(
      stats: results[0] as CommunityIssueStats,
      recent: results[1] as List<Issue>,
    );
  }

  Future<void> _openSource(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open source link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixMyCity')),
      body: FutureBuilder<_HomeData>(
        future: _future,
        builder: (context, snap) {
          final data = snap.data;
          final stats = data?.stats;
          final recent = data?.recent ?? const <Issue>[];

          final submitted = stats?.submitted ?? 0;
          final inProgress = stats?.inProgress ?? 0;
          final resolved = stats?.resolved ?? 0;

          if (snap.connectionState == ConnectionState.waiting &&
              recent.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError && recent.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 36,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'You need to sign in',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
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
                            color: AppColors.primary.withValues(alpha: 0.10),
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
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
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

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.info_outline, color: AppColors.muted),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Important Notice',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'FixMyCity is not a government app and does not represent any government entity. Government services and final issue handling are performed by official municipal authorities.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openSource(_sourceMunicipal),
                              icon: const Icon(Icons.link),
                              label: const Text('Municipal Source'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openSource(_sourceOntario),
                              icon: const Icon(Icons.link),
                              label: const Text('Ontario Source'),
                            ),
                          ],
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
                    Expanded(
                      child: StatTile(title: 'Submitted', value: '$submitted'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        title: 'In Progress',
                        value: '$inProgress',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(title: 'Resolved', value: '$resolved'),
                    ),
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
                          Icon(
                            Icons.description,
                            size: 36,
                            color: AppColors.muted,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No reports yet',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Be the first to report an issue!',
                            style: TextStyle(color: AppColors.muted),
                          ),
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
                                builder:
                                    (_) => ReportDetailsScreen(issue: issue),
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

class _HomeData {
  final CommunityIssueStats stats;
  final List<Issue> recent;

  const _HomeData({required this.stats, required this.recent});
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
