import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/theme.dart';
import '../../models/report_draft.dart';
import '../../widgets/step_dots.dart';
import '../../widgets/location_map.dart';

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

  Timer? _debounce;
  bool _validating = false;
  bool _addressValid = false;
  String? _addressError;
  String _lastValidatedAddress = '';

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = widget.draft.address ?? '';
    _addressCtrl.addListener(_onAddressChanged);

    final initial = _addressCtrl.text.trim();
    if (initial.isNotEmpty && widget.draft.latitude != null) {
      _addressValid = true;
      _lastValidatedAddress = initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressCtrl.removeListener(_onAddressChanged);
    _addressCtrl.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final typed = _addressCtrl.text.trim();
    widget.draft.address = typed.isEmpty ? null : typed;

    if (typed != _lastValidatedAddress) {
      _addressValid = false;
      _addressError = null;

      if (typed.isNotEmpty) {
        widget.draft.latitude = null;
        widget.draft.longitude = null;
      }
    }

    _debounce?.cancel();
    if (typed.isEmpty) {
      if (mounted) setState(() {});
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 650), () {
      _validateAddress(typed);
    });

    if (mounted) setState(() {});
  }

  Future<void> _validateAddress(String address) async {
    if (_validating) return;

    setState(() {
      _validating = true;
      _addressError = null;
    });

    try {
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        if (!mounted) return;
        setState(() {
          _addressValid = false;
          _addressError = 'Could not find that address. Try adding city/province.';
          _validating = false;
        });
        return;
      }

      final loc = locations.first;

      String? normalized;
      try {
        final placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
            if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
            if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
            if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
          ];
          normalized = parts.isEmpty ? null : parts.join(', ');
        }
      } catch (_) {
        normalized = null;
      }

      if (!mounted) return;

      final currentTyped = _addressCtrl.text.trim();
      if (currentTyped != address) {
        setState(() => _validating = false);
        return;
      }

      setState(() {
        _addressValid = true;
        _validating = false;
        _addressError = null;

        widget.draft.latitude = loc.latitude;
        widget.draft.longitude = loc.longitude;

        if (normalized != null && normalized.isNotEmpty) {
          widget.draft.address = normalized;
          _addressCtrl.text = normalized;
          _addressCtrl.selection =
              TextSelection.fromPosition(TextPosition(offset: _addressCtrl.text.length));
          _lastValidatedAddress = normalized;
        } else {
          _lastValidatedAddress = address;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addressValid = false;
        _addressError = 'Could not validate address. Check spelling and try again.';
        _validating = false;
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _toast('Location services are disabled.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _toast('Location permission denied.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      String? resolvedAddress;
      try {
        final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
            if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
            if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
            if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
          ];
          resolvedAddress = parts.isEmpty ? null : parts.join(', ');
        }
      } catch (_) {
        resolvedAddress = null;
      }

      if (!mounted) return;

      setState(() {
        widget.draft.latitude = pos.latitude;
        widget.draft.longitude = pos.longitude;

        if (resolvedAddress != null && resolvedAddress.isNotEmpty) {
          widget.draft.address = resolvedAddress;
          _addressCtrl.text = resolvedAddress;
          _addressCtrl.selection =
              TextSelection.fromPosition(TextPosition(offset: _addressCtrl.text.length));

          _addressValid = true;
          _addressError = null;
          _lastValidatedAddress = resolvedAddress;
        } else {
          _addressValid = false;
          _addressError = null;
        }
      });

      _toast(resolvedAddress != null ? 'Location set.' : 'Location pinned (address unavailable).');
    } catch (_) {
      _toast('Could not get location. Try again.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _canContinue {
    final addr = _addressCtrl.text.trim();
    widget.draft.address = addr.isEmpty ? null : addr;

    final hasCoords = widget.draft.latitude != null && widget.draft.longitude != null;
    final hasValidAddress = addr.isNotEmpty && _addressValid;

    return hasCoords || hasValidAddress;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const StepDots(current: 2, total: 4),
        const SizedBox(height: 16),
        const Text(
          'Where is the issue?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Use your current location or enter an address',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),

        Container(
          height: 180,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LocationMapPreview(
            latitude: widget.draft.latitude,
            longitude: widget.draft.longitude,
            address: widget.draft.address,
          ),
        ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _locating ? null : _useCurrentLocation,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            child: _locating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
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
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            errorText: _addressError,
            helperText: _validating
                ? 'Validating address...'
                : (_addressValid && _addressCtrl.text.trim().isNotEmpty
                    ? 'Address found ✓'
                    : null),
            suffixIcon: _addressCtrl.text.trim().isEmpty
                ? null
                : (_validating
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_addressValid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : (_addressError != null
                            ? const Icon(Icons.error, color: Colors.red)
                            : null))),
          ),
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
                onPressed: _canContinue ? widget.onNext : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
