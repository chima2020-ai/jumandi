import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final bookings = context.read<BookingProvider>();
    await Future.wait([
      bookings.loadPendingBookings(),
      bookings.loadMyDeliveries(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>();
    final pending = bookings.pendingBookings.length;
    final active = bookings.deliveryBookings
        .where(
          (b) =>
              b.status == BookingStatus.accepted ||
              b.status == BookingStatus.inTransit,
        )
        .length;
    final completed = bookings.deliveryBookings
        .where((b) => b.status == BookingStatus.delivered)
        .length;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const DeliveryAppBar(),
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.brandYellow,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: const Border(left: BorderSide(color: AppColors.brandYellow, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DELIVERY PORTAL', style: AppTextStyles.label),
                  const SizedBox(height: 8),
                  Text(
                    'You are online and ready for orders',
                    style: AppTextStyles.heading.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_shipping, color: AppColors.brandYellow, size: 16),
                      const SizedBox(width: 6),
                      Text('Driver account active', style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _statCard('Pending', '$pending', 'New orders waiting')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('Active', '$active', 'In progress now')),
              ],
            ),
            const SizedBox(height: 12),
            _statCard('Completed', '$completed', 'Delivered by you', fullWidth: true),
            const SizedBox(height: 24),
            Text('Quick Actions', style: AppTextStyles.headingSmall),
            const SizedBox(height: 12),
            _actionTile(
              context,
              Icons.assignment_outlined,
              'View pending requests',
              pending > 0 ? '$pending new order(s) waiting' : 'No pending orders right now',
              '/delivery/requests',
            ),
            _actionTile(
              context,
              Icons.history,
              'Delivery history',
              '$completed completed deliveries',
              '/delivery/history',
            ),
            _actionTile(
              context,
              Icons.person_outline,
              'Driver profile',
              'Account and availability',
              '/delivery/profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String sub, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.label),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 28)),
          const SizedBox(height: 4),
          Text(sub, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.brandYellow),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
