import 'package:flutter/material.dart';
import '../../models/report_draft.dart';
import 'report_step_category.dart';
import 'report_step_location.dart';
import 'report_step_details.dart';
import 'report_step_photo.dart';
import 'report_review_submit.dart';

class ReportFlowScreen extends StatefulWidget {
  const ReportFlowScreen({super.key});

  @override
  State<ReportFlowScreen> createState() => _ReportFlowScreenState();
}

class _ReportFlowScreenState extends State<ReportFlowScreen> {
  int step = 0; // 0..4
  final draft = ReportDraft();

  void next() => setState(() => step++);
  void back() => setState(() => step--);

void reset() {
  setState(() {
    step = 0;
    draft.category = null;
    draft.latitude = null;
    draft.longitude = null;
    draft.address = null;
    draft.description = null;
    draft.photoPath = null;
  });
}

@override
  Widget build(BuildContext context) {
    final steps = [
      ReportStepCategory(draft: draft, onNext: next),
      ReportStepLocation(draft: draft, onNext: next, onBack: back),
      ReportStepDetails(draft: draft, onNext: next, onBack: back),
      ReportStepPhoto(draft: draft, onNext: next, onBack: back),
      ReportReviewSubmit(draft: draft, onBack: back, onDone: reset),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: steps[step],
    );
  }
}
