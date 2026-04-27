import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/report_draft.dart';
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
      );
      if (!validation.valid) {
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

    // Copy the picked image out of the temp cache so it still exists on submit.
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
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),

        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: path == null
              ? const Center(
                  child: Text('No photo selected', style: TextStyle(color: AppColors.muted)),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(File(path), fit: BoxFit.cover),
                ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _picking ? null : () => _pick(ImageSource.camera),
                child: const Text('Take Photo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _picking ? null : () => _pick(ImageSource.gallery),
                child: const Text('Upload'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'Tip: Avoid faces and license plates if possible. Do not report emergencies.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
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
                onPressed: widget.draft.isStep4Valid ? widget.onNext : null,
                child: const Text('Review'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}