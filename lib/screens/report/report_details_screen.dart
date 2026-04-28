import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/theme.dart';
import '../../models/issue.dart';
import '../../widgets/fmc_status_chip.dart';

class ReportDetailsScreen extends StatelessWidget {
  final Issue issue;
  static const String _photosBucket = String.fromEnvironment(
    'SUPABASE_PHOTOS_BUCKET',
    defaultValue: 'issue-photos',
  );

  const ReportDetailsScreen({super.key, required this.issue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderLight),
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.bgCard,
                  ),
                  child: _buildPhoto(issue.photoPath),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        issue.category.label,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ),
                    FmcStatusChip(status: issue.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  issue.description,
                  style: const TextStyle(color: AppColors.textMain),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Reference ID', value: issue.id),
                _InfoRow(label: 'Created', value: _formatDate(issue.createdAt)),
                _InfoRow(label: 'Address', value: issue.address?.trim().isNotEmpty == true ? issue.address!.trim() : '—'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.cardSoft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status Timeline', style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 10),
                _TimelineItem(
                  title: 'Submitted',
                  subtitle: 'Your report has been received.',
                  active: true,
                ),
                _TimelineItem(
                  title: 'In Progress',
                  subtitle: 'City staff are reviewing / dispatching.',
                  active: issue.status == IssueStatus.inProgress || issue.status == IssueStatus.resolved,
                ),
                _TimelineItem(
                  title: 'Resolved',
                  subtitle: 'Issue has been marked as resolved.',
                  active: issue.status == IssueStatus.resolved,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String? path) {
    if (path == null || path.trim().isEmpty) {
      return const Center(child: Text('No photo', style: TextStyle(color: AppColors.textMuted)));
    }

    final trimmed = path.trim();
    final isRemote = trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final isLikelyStoragePath = !trimmed.startsWith('/') && !trimmed.contains('\\');

    if (isRemote) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          trimmed,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Could not load photo', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    if (isLikelyStoragePath) {
      final publicUrl = Supabase.instance.client.storage
          .from(_photosBucket)
          .getPublicUrl(trimmed);

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          publicUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Text('Could not load photo', style: TextStyle(color: AppColors.textMuted)),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(trimmed),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Text('Could not load photo', style: TextStyle(color: AppColors.textMuted)),
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: AppColors.textMain))),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.subtitle,
    required this.active,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.borderLight,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: active ? AppColors.primary : AppColors.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
