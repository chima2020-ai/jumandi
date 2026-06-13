import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/booking_card.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ApiService _api;
  final LocationService _locationService = LocationService();
  StreamSubscription<Map<String, dynamic>>? _notificationSub;
  StreamSubscription? _locationSub;
  int? _activeTransitId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _api = context.read<ApiService>();
      _loadAll();
      _listenNotifications();
    });
  }

  void _listenNotifications() {
    final ws = context.read<WebSocketService>();
    final token = context.read<AuthProvider>().token;
    if (token != null) {
      ws.connectNotifications(token);
      _notificationSub = ws.notifications.listen((event) {
        if (event['type'] == 'new_booking') {
          context.read<BookingProvider>().loadPendingBookings();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('New booking received!')),
            );
          }
        }
      });
    }
  }

  Future<void> _loadAll() async {
    final provider = context.read<BookingProvider>();
    await provider.loadPendingBookings();
    await provider.loadMyDeliveries();
  }

  Future<void> _logout() async {
    _locationSub?.cancel();
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/welcome');
  }

  Future<void> _accept(BookingModel booking) async {
    final ok = await context.read<BookingProvider>().acceptBooking(booking.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking accepted')),
      );
      _loadAll();
    }
  }

  Future<void> _start(BookingModel booking) async {
    final ok = await context.read<BookingProvider>().startDelivery(booking.id);
    if (!mounted) return;
    if (ok) {
      setState(() => _activeTransitId = booking.id);
      _startLocationSharing();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery started — customer can track you')),
      );
      _loadAll();
    }
  }

  Future<void> _complete(BookingModel booking) async {
    final ok = await context.read<BookingProvider>().completeDelivery(booking.id);
    if (!mounted) return;
    if (ok) {
      if (_activeTransitId == booking.id) {
        _locationSub?.cancel();
        _activeTransitId = null;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery completed')),
      );
      _loadAll();
    }
  }

  void _startLocationSharing() {
    _locationSub?.cancel();
    _locationSub = _locationService.watchPosition((position) async {
      try {
        await _api.updateLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } catch (_) {}
    });
  }

  Widget? _buildDeliveryActions(BookingModel b) {
    if (b.status == BookingStatus.accepted) {
      return TextButton(onPressed: () => _start(b), child: const Text('Start'));
    }
    if (b.status == BookingStatus.inTransit) {
      return TextButton(onPressed: () => _complete(b), child: const Text('Complete'));
    }
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notificationSub?.cancel();
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'My deliveries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: bookings.loadPendingBookings,
            child: bookings.pendingBookings.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No pending bookings')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.pendingBookings.length,
                    itemBuilder: (_, i) {
                      final b = bookings.pendingBookings[i];
                      return BookingCard(
                        booking: b,
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => _accept(b),
                        ),
                      );
                    },
                  ),
          ),
          RefreshIndicator(
            onRefresh: _loadAll,
            child: bookings.deliveryBookings.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('No assigned deliveries')),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.deliveryBookings.length,
                    itemBuilder: (_, i) {
                      final b = bookings.deliveryBookings[i];
                      return BookingCard(
                        booking: b,
                        trailing: _buildDeliveryActions(b),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
