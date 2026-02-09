import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/material.dart';

enum IssueCategory {
  pothole('Pothole', LucideIcons.alertTriangle),
  streetlight('Streetlight', LucideIcons.lightbulb),
  graffiti('Graffiti', LucideIcons.brush),
  sidewalk('Sidewalk', LucideIcons.user),
  dumping('Illegal Dumping', LucideIcons.trash2),
  other('Other', LucideIcons.moreHorizontal);

  final String label;
  final IconData icon;
  const IssueCategory(this.label, this.icon);
}
