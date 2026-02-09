import 'package:flutter/material.dart';
import '../../widgets/step_dots.dart';
import '../../models/report_draft.dart';
import '../../models/issue_category.dart';
import '../../app/theme.dart';

class ReportStepCategory extends StatefulWidget {
  final ReportDraft draft;
  final VoidCallback onNext;

  const ReportStepCategory({super.key, required this.draft, required this.onNext});

  @override
  State<ReportStepCategory> createState() => _ReportStepCategoryState();
}

class _ReportStepCategoryState extends State<ReportStepCategory> {
  @override
  Widget build(BuildContext context) {
    final selected = widget.draft.category;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StepDots(current: 1, total: 4),
        const SizedBox(height: 16),
        const Text('What type of issue?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Select a category that best describes the problem',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
          ),
          itemCount: IssueCategory.values.length,
          itemBuilder: (_, i) {
            final cat = IssueCategory.values[i];
            final active = selected == cat;

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => widget.draft.category = cat),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white,
                  border: Border.all(
                    color: active ? AppColors.primary : AppColors.border,
                    width: active ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: AppColors.primary),
                    ),
                    const SizedBox(height: 10),
                    Text(cat.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),
        FilledButton(
          onPressed: widget.draft.isStep1Valid ? widget.onNext : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
