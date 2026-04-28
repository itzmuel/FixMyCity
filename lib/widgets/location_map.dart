import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationMapPreview extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final String? address;

  const LocationMapPreview({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  State<LocationMapPreview> createState() => _LocationMapPreviewState();
}

class _LocationMapPreviewState extends State<LocationMapPreview> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _updateCameraAndMarkers();
  }

  void _updateCameraAndMarkers() {
    final hasLocation = widget.latitude != null && widget.longitude != null;
    final latLng = hasLocation
        ? LatLng(widget.latitude!, widget.longitude!)
        : const LatLng(43.4516, -80.4925); // Waterloo, ON default

    _initialCameraPosition = CameraPosition(
      target: latLng,
      zoom: hasLocation ? 15 : 12,
    );

    _markers.clear();

    if (hasLocation) {
      _markers.add(
        Marker(
          markerId: const MarkerId('location_pin'),
          position: LatLng(widget.latitude!, widget.longitude!),
          infoWindow: InfoWindow(
            title: 'Issue Location',
            snippet: widget.address ?? 'Selected location',
          ),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(LocationMapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.address != widget.address) {
      _updateCameraAndMarkers();

      if (widget.latitude != null &&
          widget.longitude != null &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(widget.latitude!, widget.longitude!),
              zoom: 15,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        zoomControlsEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}