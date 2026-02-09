import 'package:flutter/material.dart';
import '../../models/report_draft.dart';
import '../../widgets/step_dots.dart';
import '../../app/theme.dart';

class ReportStepDetails extends StatefulWidget {
  final ReportDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ReportStepDetails({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ReportStepDetails> createState() => _ReportStepDetailsState();
}

class _ReportStepDetailsState extends State<ReportStepDetails> {
  final _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descCtrl.text = widget.draft.description ?? '';
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    final d = _descCtrl.text.trim();
    widget.draft.description = d.isEmpty ? null : d;
    return widget.draft.isStep3Valid;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StepDots(current: 3, total: 4),
        const SizedBox(height: 16),
        const Text('Describe the issue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Provide details to help the city respond faster',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),

        TextField(
          controller: _descCtrl,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: 'Description',
            hintText: 'Example: Large pothole in the right lane causing cars to swerve.',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _canContinue ? widget.onNext : null,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
