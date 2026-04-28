import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets current position and a best-effort human-readable address.
  Future<({double lat, double lng, String? address})> getCurrentLocationWithAddress() async {
    // Ensure location permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      throw Exception('Location permission not granted.');
    }

    // NOTE: desiredAccuracy is deprecated — use LocationSettings instead
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    String? address;

    try {
      final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Build a clean address string (best effort)
        final parts = <String>[
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
          if ((p.administrativeArea ?? '').trim().isNotEmpty) p.administrativeArea!.trim(),
          if ((p.postalCode ?? '').trim().isNotEmpty) p.postalCode!.trim(),
        ];

        address = parts.isEmpty ? null : parts.join(', ');
      }
    } catch (_) {
      // If geocoding fails, we still return lat/lng
      address = null;
    }

    return (lat: pos.latitude, lng: pos.longitude, address: address);
  }
}

final locationService = LocationService();
