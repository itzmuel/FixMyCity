import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../models/issue.dart';
import '../services/issue_service.dart';
import 'report/report_details_screen.dart';

class CommunityReportsScreen extends StatefulWidget {
  const CommunityReportsScreen({super.key});

  @override
  State<CommunityReportsScreen> createState() => _CommunityReportsScreenState();
}

class _CommunityReportsScreenState extends State<CommunityReportsScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  final List<Issue> _issues = [];
  int _nextPage = 1;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _loadingInitial ||
        _loadingMore ||
        !_hasMore) {
      return;
    }

    const threshold = 320.0;
    final position = _scrollController.position;
    final remaining = position.maxScrollExtent - position.pixels;

    if (remaining <= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loadingInitial = true;
      _error = null;
      _issues.clear();
      _nextPage = 1;
      _hasMore = true;
    });

    await _loadPage(isInitial: true);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;

    setState(() {
      _loadingMore = true;
    });

    await _loadPage(isInitial: false);
  }

  Future<void> _loadPage({required bool isInitial}) async {
    try {
      final page = await issueService.getCommunityReports(
        pageNumber: _nextPage,
        pageSize: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _issues.addAll(page);
        _nextPage += 1;
        _hasMore = page.length == _pageSize;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (isInitial) {
          _error = e.toString();
        }
      });

      if (!isInitial) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not load more reports. Pull to refresh and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingInitial = false;
          _loadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Reports')),
      body: Builder(
        builder: (context) {
          if (_loadingInitial && _issues.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_error != null && _issues.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 36,
                          color: AppColors.muted,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Could not load community reports',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pull down to refresh and try again.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadInitial,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (_issues.isEmpty) {
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
                        Text(
                          'No community reports yet',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: _issues.length + 1,
              separatorBuilder: (_, index) => index == _issues.length - 1
                  ? const SizedBox.shrink()
                  : const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i >= _issues.length) {
                  if (_loadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (!_hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'You have reached the end.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                }

                final issue = _issues[i];

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
        border: Border.all(color: bg.withValues(alpha: 0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}
