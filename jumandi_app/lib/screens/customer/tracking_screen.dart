import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  BookingModel? _booking;
  GoogleMapController? _mapController;
  LatLng? _agentPosition;
  StreamSubscription<Map<String, dynamic>>? _trackingSub;
  WebSocketService? _ws;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final api = context.read<ApiService>();
    final ws = context.read<WebSocketService>();
    _ws = ws;
    final token = auth.token;
    if (token == null) return;

    try {
      final booking = await api.getBooking(widget.bookingId);
      ws.connectTracking(bookingId: widget.bookingId, token: token);
      _trackingSub = ws.trackingUpdates.listen((event) {
        if (event['type'] == 'location_update') {
          final lat = (event['latitude'] as num).toDouble();
          final lng = (event['longitude'] as num).toDouble();
          setState(() => _agentPosition = LatLng(lat, lng));
          _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
        }
      });

      if (booking.deliveryAgent?.currentLat != null) {
        _agentPosition = LatLng(
          booking.deliveryAgent!.currentLat!,
          booking.deliveryAgent!.currentLng!,
        );
      }

      setState(() {
        _booking = booking;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _trackingSub?.cancel();
    _ws?.disconnectTracking();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    if (_booking == null) return {};
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('destination'),
        position: LatLng(_booking!.latitude, _booking!.longitude),
        infoWindow: const InfoWindow(title: 'Your location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };
    if (_agentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('agent'),
          position: _agentPosition!,
          infoWindow: const InfoWindow(title: 'Delivery agent'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track delivery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final center = _agentPosition ?? LatLng(_booking!.latitude, _booking!.longitude);

    return Scaffold(
      appBar: AppBar(title: const Text('Track delivery')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 14),
        markers: _buildMarkers(),
        myLocationEnabled: true,
        onMapCreated: (c) => _mapController = c,
      ),
    );
  }
}
