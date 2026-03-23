import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/refresh_bus.dart';
import '../../models/report_draft.dart';
import '../../services/issue_service.dart';

class ReportReviewSubmit extends StatefulWidget {
  final ReportDraft draft;
  final VoidCallback onBack;
  final VoidCallback onDone;

  const ReportReviewSubmit({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onDone,
  });

  @override
  State<ReportReviewSubmit> createState() => _ReportReviewSubmitState();
}

class _ReportReviewSubmitState extends State<ReportReviewSubmit> {
  bool _submitting = false;

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (!widget.draft.isReadyToSubmit) return;

    setState(() => _submitting = true);

    try {
      await issueService.submitReport(widget.draft);
      if (!mounted) return;

      // ✅ Immediately update Home + My Reports data
      refreshBus.pingHome();
      refreshBus.pingMyReports();

      // ✅ Reset flow (clear draft + go back to first step)
      widget.onDone();

      // ✅ Navigate to My Reports
      context.go('/my-reports');

      // ✅ Show feedback on My Reports after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted! Your report is now in My Reports.')),
        );
      });
    } catch (e) {
      if (!mounted) return;

      if (e is StateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your session expired. Please sign in again.')),
        );
        context.go('/auth');
        setState(() => _submitting = false);
        return;
      }

      // Provide explicit submit errors so backend/config issues are visible.
      final errorText = e.toString().toLowerCase();
      String userMessage = 'Could not submit report. Please try again.';
      if (errorText.contains('failed to fetch') ||
          errorText.contains('connection') ||
          errorText.contains('socketexception') ||
          errorText.contains('network')) {
        userMessage =
            'Cannot reach Supabase right now. Check internet connection and project API settings.';
      } else if (errorText.contains('401') ||
          errorText.contains('403') ||
          errorText.contains('jwt') ||
          errorText.contains('not authorized') ||
          errorText.contains('permission')) {
        userMessage = 'Access denied. Please sign in again.';
      } else if (errorText.contains('postgrestexception') ||
          errorText.contains('violates') ||
          errorText.contains('rls')) {
        userMessage =
            'Server rejected this report. Verify database policies/schema and try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          duration: const Duration(seconds: 4),
        ),
      );

      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = widget.draft.isReadyToSubmit && !_submitting;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Review & Submit',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Confirm your report details before submitting.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),

        _ReviewCard(
          title: 'Category',
          value: widget.draft.category?.label ?? '—',
        ),
        const SizedBox(height: 10),

        _ReviewCard(
          title: 'Location',
          value: _locationText(widget.draft),
        ),
        const SizedBox(height: 10),

        _ReviewCard(
          title: 'Description',
          value: widget.draft.description ?? '—',
        ),
        const SizedBox(height: 10),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Photo', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                  ),
                  child: widget.draft.photoPath == null
                      ? const Center(
                          child: Text('—', style: TextStyle(color: AppColors.muted)),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(widget.draft.photoPath!),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: canSubmit ? _handleSubmit : null,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),
        const Text(
          'By submitting, you confirm this is a non-emergency municipal issue and does not contain personal information.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  static String _locationText(ReportDraft d) {
    return d.address?.trim().isNotEmpty == true ? d.address!.trim() : '—';
  }
}

class _ReviewCard extends StatelessWidget {
  final String title;
  final String value;

  const _ReviewCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
