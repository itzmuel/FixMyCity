import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/report_draft.dart';
import '../../widgets/step_dots.dart';
import '../../app/theme.dart';

class ReportStepLocation extends StatefulWidget {
  final ReportDraft draft;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ReportStepLocation({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ReportStepLocation> createState() => _ReportStepLocationState();
}

class _ReportStepLocationState extends State<ReportStepLocation> {
  final _addressCtrl = TextEditingController();
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = widget.draft.address ?? '';
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);

    try {
      // 1) service enabled?
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Location services are disabled.');
        return;
      }

      // 2) permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _toast('Location permission denied.');
        return;
      }

      // 3) get location
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        widget.draft.latitude = pos.latitude;
        widget.draft.longitude = pos.longitude;
        // Keep address text if user already typed it
      });

      _toast('Location captured: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}');
    } catch (_) {
      _toast('Could not get location. Try again.');
    } finally {
      setState(() => _locating = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _canContinue {
    final addr = _addressCtrl.text.trim();
    // Save address field into draft every build for simplicity:
    widget.draft.address = addr.isEmpty ? null : addr;

    return widget.draft.isStep2Valid;
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.draft.latitude;
    final lng = widget.draft.longitude;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StepDots(current: 2, total: 4),
        const SizedBox(height: 16),
        const Text('Where is the issue?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        const Text('Use your current location or enter an address',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 12),

        // Map placeholder (you can replace later with Google Maps)
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              lat != null && lng != null
                  ? 'Pinned at:\n${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'
                  : 'Map Preview (placeholder)',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _locating ? null : _useCurrentLocation,
            child: _locating
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Use Current Location'),
          ),
        ),

        const SizedBox(height: 12),

        TextField(
          controller: _addressCtrl,
          decoration: InputDecoration(
            labelText: 'Address (optional if location used)',
            hintText: 'e.g., 123 King St N, Waterloo',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
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
