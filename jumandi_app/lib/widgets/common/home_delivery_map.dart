import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/app_colors.dart';
import '../../config/maps_config.dart';
import '../../models/booking_model.dart';

/// In-app OpenStreetMap — no external links, no API key.
class HomeDeliveryMap extends StatelessWidget {
  const HomeDeliveryMap({
    super.key,
    required this.mapController,
    required this.booking,
    required this.userPosition,
    required this.agentPosition,
    this.onMapReady,
    this.fullBleed = false,
  });

  final MapController mapController;
  final BookingModel? booking;
  final LatLng? userPosition;
  final LatLng? agentPosition;
  final VoidCallback? onMapReady;
  final bool fullBleed;

  LatLng get _center {
    if (agentPosition != null) return agentPosition!;
    if (booking != null) return LatLng(booking!.latitude, booking!.longitude);
    if (userPosition != null) return userPosition!;
    return const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng);
  }

  List<LatLng> _routePoints() {
    if (agentPosition == null || booking == null) return [];
    return [
      agentPosition!,
      LatLng(booking!.latitude, booking!.longitude),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];

    if (userPosition != null) {
      markers.add(_pin(userPosition!, AppColors.brandYellow, 'You'));
    }
    if (booking != null) {
      markers.add(_pin(LatLng(booking!.latitude, booking!.longitude), AppColors.success, 'Delivery'));
    }
    if (agentPosition != null) {
      markers.add(_pin(agentPosition!, AppColors.logoOrange, 'Driver'));
    }

    final route = _routePoints();

    final map = FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14,
        onMapReady: onMapReady,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.jumandi.app',
          maxZoom: 19,
        ),
        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                color: AppColors.brandYellow,
                strokeWidth: 4,
              ),
            ],
          ),
        if (markers.isNotEmpty) MarkerLayer(markers: markers),
      ],
    );

    if (fullBleed) return map;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: map,
    );
  }

  Marker _pin(LatLng point, Color color, String label) {
    return Marker(
      point: point,
      width: 44,
      height: 44,
      child: Tooltip(
        message: label,
        child: Icon(Icons.location_on, color: color, size: 40),
      ),
    );
  }
}
