import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/maps_config.dart';
import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../services/call_service.dart';
import '../../services/location_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/common/home_delivery_map.dart';
import '../../widgets/common/jumandi_logo.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  final _locationService = LocationService();
  final _mapController = MapController();
  LatLng? _userPosition;
  LatLng? _agentPosition;
  String? _userAddress;
  String? _locationError;
  bool _locationNeedsSettings = false;
  bool _loadingLocation = false;
  bool _loadingAddress = false;
  StreamSubscription<Map<String, dynamic>>? _trackingSub;
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  WebSocketService? _ws;
  int? _trackingBookingId;
  int? _lastSyncedBookingId;
  BookingStatus? _lastSyncedStatus;
  bool _mapReady = false;
  bool _mapExpanded = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _listenForBookingUpdates();
      _loadLocation();
      await context.read<BookingProvider>().loadCustomerBookings();
      if (mounted) {
        _onBookingChanged(context.read<BookingProvider>().currentCustomerBooking);
      }
      _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refresh());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _trackingSub?.cancel();
    _notificationSub?.cancel();
    _ws?.disconnectTracking();
    _mapController.dispose();
    super.dispose();
  }

  void _listenForBookingUpdates() {
    _notificationSub?.cancel();
    _ws = context.read<WebSocketService>();
    _notificationSub = _ws!.notifications.listen((event) {
      final type = event['type'] as String?;
      if (type == 'booking_accepted' ||
          type == 'delivery_started' ||
          type == 'delivery_completed' ||
          type == 'location_update') {
        _refresh();
      }
    });
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() {
        _loadingLocation = true;
        _loadingAddress = false;
        _locationError = null;
        _locationNeedsSettings = false;
      });
    }

    final posDetails = await _locationService.getCurrentPositionDetails();
    if (!mounted) return;

    if (!posDetails.hasPosition) {
      setState(() {
        _loadingLocation = false;
        _locationError = posDetails.errorMessage ??
            'Could not detect your location. Tap below to try again.';
        _locationNeedsSettings = posDetails.needsSettings;
      });
      return;
    }

    final position = posDetails.position!;
    setState(() {
      _userPosition = LatLng(position.latitude, position.longitude);
      _loadingLocation = false;
      _loadingAddress = true;
      _locationError = null;
    });
    if (!mounted) return;
    _fitMapToMarkers(context.read<BookingProvider>().currentCustomerBooking);

    final address = await _locationService.getAddress(position.latitude, position.longitude);
    if (!mounted) return;
    setState(() {
      _userAddress = address;
      _loadingAddress = false;
    });
  }

  Future<void> _refresh() async {
    await _loadLocation();
    if (!mounted) return;
    await context.read<BookingProvider>().loadCustomerBookings();
    if (!mounted) return;
    _onBookingChanged(context.read<BookingProvider>().currentCustomerBooking);
  }

  bool _shouldTrack(BookingModel? booking) {
    if (booking == null || booking.deliveryAgentId == null) return false;
    return booking.status == BookingStatus.accepted ||
        booking.status == BookingStatus.inTransit;
  }

  void _onBookingChanged(BookingModel? booking) {
    if (booking?.id == _lastSyncedBookingId && booking?.status == _lastSyncedStatus) {
      return;
    }
    _lastSyncedBookingId = booking?.id;
    _lastSyncedStatus = booking?.status;

    if (booking != null &&
        (booking.status == BookingStatus.accepted ||
            booking.status == BookingStatus.inTransit)) {
      _mapExpanded = true;
    }

    setState(() {
      if (booking?.deliveryAgent?.currentLat != null) {
        _agentPosition = LatLng(
          booking!.deliveryAgent!.currentLat!,
          booking.deliveryAgent!.currentLng!,
        );
      } else if (!_shouldTrack(booking)) {
        _agentPosition = null;
      }
    });

    _syncTracking(booking);
    _fitMapToMarkers(booking);
  }

  void _syncTracking(BookingModel? booking) {
    if (!_shouldTrack(booking)) {
      if (_trackingBookingId != null) {
        _trackingSub?.cancel();
        _trackingBookingId = null;
        _ws?.disconnectTracking();
      }
      return;
    }

    if (_trackingBookingId == booking!.id) return;

    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    _trackingSub?.cancel();
    _trackingBookingId = booking.id;
    _ws!.connectTracking(bookingId: booking.id, token: token);

    if (booking.deliveryAgent?.currentLat != null) {
      setState(() {
        _agentPosition = LatLng(
          booking.deliveryAgent!.currentLat!,
          booking.deliveryAgent!.currentLng!,
        );
      });
    }

    _trackingSub = _ws!.trackingUpdates.listen((event) {
      if (event['type'] != 'location_update' || !mounted) return;
      final lat = (event['latitude'] as num).toDouble();
      final lng = (event['longitude'] as num).toDouble();
      setState(() => _agentPosition = LatLng(lat, lng));
      if (_mapReady) {
        _mapController.move(LatLng(lat, lng), _mapController.camera.zoom);
      }
    });
  }

  void _fitMapToMarkers(BookingModel? booking) {
    if (!_mapReady) return;

    final points = <LatLng>[];
    if (_userPosition != null) points.add(_userPosition!);
    if (booking != null) points.add(LatLng(booking.latitude, booking.longitude));
    if (_agentPosition != null) points.add(_agentPosition!);

    if (points.isEmpty) {
      _mapController.move(const LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng), 12);
      return;
    }

    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(48, 120, 48, 220),
      ),
    );
  }

  void _openFullScreenMap() {
    setState(() => _mapExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitMapToMarkers(context.read<BookingProvider>().currentCustomerBooking);
    });
  }

  void _closeFullScreenMap() {
    setState(() => _mapExpanded = false);
  }

  Future<void> _callDriver(BookingModel booking) async {
    try {
      await context.read<CallService>().startCall(booking.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final current = provider.currentCustomerBooking;
    final canCall = provider.activeCustomerBooking;
    _onBookingChanged(current);

    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: HomeDeliveryMap(
              mapController: _mapController,
              booking: current,
              userPosition: _userPosition,
              agentPosition: _agentPosition,
              fullBleed: true,
              onMapReady: () {
                _mapReady = true;
                _fitMapToMarkers(current);
              },
            ),
          ),
          if (_mapExpanded) ...[
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _closeFullScreenMap,
                      icon: const Icon(Icons.fullscreen_exit, color: AppColors.white),
                      style: IconButton.styleFrom(backgroundColor: AppColors.black.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          current != null
                              ? 'Live map • Booking #${current.id} • ${current.status.label}'
                              : 'Live map',
                          style: AppTextStyles.caption.copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, color: AppColors.brandYellow),
                      style: IconButton.styleFrom(backgroundColor: AppColors.black.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 60,
              left: 16,
              right: 16,
              child: _locationAddressBanner(),
            ),
            if (current != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 24,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping, color: AppColors.brandYellow),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          current.deliveryAgent?.name ?? 'Waiting for driver',
                          style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                        ),
                      ),
                      if (canCall != null)
                        IconButton(
                          onPressed: () => _callDriver(canCall),
                          icon: const Icon(Icons.phone, color: AppColors.brandGold),
                        ),
                    ],
                  ),
                ),
              ),
          ] else ...[
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.black.withValues(alpha: 0.85),
                      AppColors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Row(
                      children: [
                        const JumandiWordmark(),
                        const Spacer(),
                        IconButton(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh, color: AppColors.brandYellow),
                        ),
                        IconButton(
                          onPressed: _openFullScreenMap,
                          icon: const Icon(Icons.fullscreen, color: AppColors.white),
                          tooltip: 'Full screen map',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 56,
              left: 16,
              right: 16,
              child: _locationAddressBanner(),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.loading && current == null)
                    const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                  else if (provider.error != null && current == null)
                    _errorCard(provider.error!)
                  else
                    _fleetCard(context, current, canCall),
                  const SizedBox(height: 10),
                  _quickRefuelCard(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _locationAddressBanner() {
    final coords = _userPosition != null
        ? '${_userPosition!.latitude.toStringAsFixed(5)}, ${_userPosition!.longitude.toStringAsFixed(5)}'
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _locationError != null ? _loadLocation : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _locationError != null
                  ? AppColors.logoOrange.withValues(alpha: 0.6)
                  : AppColors.brandYellow.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _locationError != null ? Icons.location_off : Icons.my_location,
                color: _locationError != null ? AppColors.logoOrange : AppColors.brandYellow,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('YOUR LOCATION', style: AppTextStyles.label.copyWith(fontSize: 10)),
                    const SizedBox(height: 4),
                    if (_loadingLocation)
                      Text('Detecting GPS...', style: AppTextStyles.caption)
                    else if (_loadingAddress)
                      Text('Finding your address...', style: AppTextStyles.caption)
                    else if (_userAddress != null)
                      Text(
                        _userAddress!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.white),
                      )
                    else if (coords != null)
                      Text(coords, style: AppTextStyles.caption)
                    else if (_locationError != null)
                      Text(
                        _locationError!,
                        style: AppTextStyles.caption.copyWith(color: AppColors.logoOrange),
                      )
                    else
                      Text('Tap to detect your location', style: AppTextStyles.caption),
                    if (_locationError != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton(
                            onPressed: _loadLocation,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.brandYellow,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text('Retry'),
                          ),
                          if (_locationNeedsSettings) ...[
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => _locationService.openLocationSettings(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.brandGold,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Open settings'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_loadingLocation || _loadingAddress)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.brandYellow,
                  ),
                )
              else if (_locationError == null && _userPosition == null)
                IconButton(
                  onPressed: _loadLocation,
                  icon: const Icon(Icons.refresh, color: AppColors.brandYellow, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Detect location',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Could not load bookings', style: AppTextStyles.headingSmall),
          const SizedBox(height: 8),
          Text(message, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _fleetCard(BuildContext context, BookingModel? booking, BookingModel? callable) {
    final driver = booking?.deliveryAgent?.name ?? 'Waiting for driver';
    final trackingHint = booking?.status == BookingStatus.inTransit
        ? 'Driver moving on map'
        : booking?.status == BookingStatus.accepted
            ? 'Driver assigned — GPS when en route'
            : booking?.status == BookingStatus.pending
                ? 'Waiting for a driver to accept'
                : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT ORDER', style: AppTextStyles.label),
                    Text(
                      booking != null ? 'Booking #${booking.id}' : 'No active order',
                      style: AppTextStyles.heading.copyWith(color: AppColors.brandGold, fontSize: 22),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('STATUS', style: AppTextStyles.label),
                  Text(booking?.status.label ?? 'IDLE', style: AppTextStyles.headingSmall),
                ],
              ),
            ],
          ),
          if (booking != null) ...[
            const SizedBox(height: 12),
            Text('${booking.gasKg.toStringAsFixed(1)} kg • $driver', style: AppTextStyles.body),
            if (trackingHint != null) ...[
              const SizedBox(height: 4),
              Text(trackingHint, style: AppTextStyles.caption.copyWith(color: AppColors.brandYellow)),
            ],
            const SizedBox(height: 4),
            Text(booking.address, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home/booking'),
                  icon: const Icon(Icons.local_gas_station, size: 18),
                  label: Text('BOOK SERVICE', style: AppTextStyles.button.copyWith(color: AppColors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellowBright,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              if (booking != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: _openFullScreenMap,
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.map, color: AppColors.brandGold),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Material(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: callable != null ? () => _callDriver(callable) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.phone,
                      color: callable != null ? AppColors.brandGold : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
              if (booking != null) ...[
                const SizedBox(width: 10),
                Material(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => context.go('/home/chat/${booking.id}'),
                    borderRadius: BorderRadius.circular(10),
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(Icons.chat_bubble_outline, color: AppColors.brandGold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickRefuelCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandYellowBright.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
            child: const Icon(Icons.speed, color: AppColors.brandYellow, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Need a quick refuel?',
              style: AppTextStyles.headingSmall.copyWith(color: AppColors.black, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/home/booking'),
            child: Text('BOOK', style: AppTextStyles.button.copyWith(color: AppColors.black, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
