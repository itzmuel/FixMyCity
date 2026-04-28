// ignore_for_file: avoid_print, dangling_library_doc_comments

/// Quick example: Using the photo validation tuning tool.
///
/// Run this as a test to analyze sample photos and see validation scores.
///
/// ```bash
/// dart run bin/tune_photo_validation.dart <sample_photo.jpg> [--category=pothole] [--description="..."]
/// ```

import 'dart:io';
import 'package:fixmycity/models/issue_category.dart';
import 'package:fixmycity/services/photo_validation_tuning.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    exit(1);
  }

  final filePath = args[0];
  final file = File(filePath);

  if (!await file.exists()) {
    print('Error: File not found: $filePath');
    exit(1);
  }

  IssueCategory? category;
  String? description;

  for (final arg in args.skip(1)) {
    if (arg.startsWith('--category=')) {
      final name = arg.replaceFirst('--category=', '');
      category = IssueCategory.values
          .cast<IssueCategory?>()
          .firstWhere(
            (c) => c?.name == name,
            orElse: () => null,
          );
    } else if (arg.startsWith('--description=')) {
      description = arg.replaceFirst('--description=', '');
    }
  }

  print('Analyzing: $filePath');
  print('Category: ${category?.label ?? "none"}');
  print('Description: ${description ?? "none"}');
  print('');

  final report = await analyzePhotoForTuning(
    filePath,
    category: category,
    description: description,
  );

  report.printAnalysis();

  if (!report.validationResult.valid) {
    exit(1);
  }
}

void printUsage() {
  print('Usage: dart run bin/tune_photo_validation.dart <photo> [options]');
  print('');
  print('Options:');
  print('  --category=<name>      Issue category (e.g., pothole, graffiti)');
  print('  --description=<text>   Issue description');
  print('');
  print('Example:');
  print('  dart run bin/tune_photo_validation.dart samples/pothole.jpg \\');
  print('    --category=pothole \\');
  print('    --description="Large pothole on Main St"');
}
