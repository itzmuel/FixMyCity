import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/report_draft.dart';
import '../../services/report_moderation_analytics_service.dart';
import '../../services/upload_validation.dart';
import '../../widgets/step_dots.dart';
import '../../app/theme.dart';

class ReportStepPhoto extends StatefulWidget {
  final ReportDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ReportStepPhoto({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ReportStepPhoto> createState() => _ReportStepPhotoState();
}

class _ReportStepPhotoState extends State<ReportStepPhoto> {
  final _picker = ImagePicker();
  bool _picking = false;

  Future<void> _pick(ImageSource source) async {
    setState(() => _picking = true);
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 80);
      if (xfile == null) return;

      final validation = await validateIssuePhoto(
        xfile.path,
        mimeType: xfile.mimeType,
        category: widget.draft.category,
        description: widget.draft.description,
      );
      if (!validation.valid) {
        await reportModerationAnalyticsService.logModerationEvent(
          eventType: 'photo_pick',
          allowed: false,
          source: 'localFallback',
          category: widget.draft.category,
          reasonCode: validation.code?.name,
          reasonMessage: validation.error,
          score: validation.score,
        );
        _toast(validation.error!);
        return;
      }

      final savedPath = await _savePickedImageToAppStorage(xfile);

      setState(() {
        widget.draft.photoPath = savedPath;
      });
    } catch (_) {
      _toast('Could not pick image.');
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  Future<String> _savePickedImageToAppStorage(XFile xfile) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${docsDir.path}/report_photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final ext = _fileExtension(xfile.name.isNotEmpty ? xfile.name : xfile.path);
    final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}$ext';
    final savedFile = File('${photosDir.path}/$fileName');

    await File(xfile.path).copy(savedFile.path);
    return savedFile.path;
  }

  String _fileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot <= 0 || dot == path.length - 1) return '.jpg';
    return path.substring(dot);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.draft.photoPath;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StepDots(current: 4, total: 4),
        const SizedBox(height: 16),
        const Text('Add a photo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Photos help city staff verify and resolve issues faster.',
            style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: path == null
              ? const Center(
                  child: Text('No photo selected', style: TextStyle(color: AppColors.textMuted)),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _picking ? null : () => _pick(ImageSource.camera),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Upload'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'Tip: Photos with faces, blur, or poor lighting are blocked before submission.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.draft.isStep4Valid ? widget.onNext : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Review'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
