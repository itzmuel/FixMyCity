import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/issue.dart';

class FmcStatusChip extends StatelessWidget {
  final IssueStatus status;
  const FmcStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;

    switch (status) {
      case IssueStatus.submitted:
        textColor = const Color(0xFF6B5B8A);
        bgColor = AppColors.primaryLight;
        break;
      case IssueStatus.inProgress:
        textColor = const Color(0xFF5A6B8A);
        bgColor = const Color(0xFFE3EBF5);
        break;
      case IssueStatus.resolved:
        textColor = const Color(0xFF5B8A6B);
        bgColor = const Color(0xFFE3F5E6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status == IssueStatus.submitted
            ? 'Submitted'
            : status == IssueStatus.inProgress
                ? 'In Progress'
                : 'Resolved',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
