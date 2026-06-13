import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryRequestsScreen extends StatefulWidget {
  const DeliveryRequestsScreen({super.key});

  @override
  State<DeliveryRequestsScreen> createState() => _DeliveryRequestsScreenState();
}

class _DeliveryRequestsScreenState extends State<DeliveryRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadPendingBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const DeliveryAppBar(),
      body: RefreshIndicator(
        onRefresh: provider.loadPendingBookings,
        color: AppColors.brandYellow,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Pending Requests', style: AppTextStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              'Accept orders and deliver gas to customers',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            if (provider.loading)
              const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
            else if (provider.pendingBookings.isEmpty) ...[
              Text('Demo order (design preview):', style: AppTextStyles.caption),
              const SizedBox(height: 8),
              _demoRequest(context),
            ] else
              ...provider.pendingBookings.map((b) => _requestCard(context, b)),
          ],
        ),
      ),
    );
  }

  Widget _demoRequest(BuildContext context) {
    return _requestCard(
      context,
      null,
      customerName: 'Alexander Vance',
      fuelType: 'Premium Diesel',
      quantity: '25 Gal',
      payout: '\$42.50',
      distance: '4.2 miles',
      eta: '12 mins',
    );
  }

  Widget _requestCard(
    BuildContext context,
    BookingModel? booking, {
    String customerName = '',
    String fuelType = '',
    String quantity = '',
    String payout = '',
    String distance = '',
    String eta = '',
  }) {
    final id = booking?.id ?? 1;
    final name = customerName.isNotEmpty ? customerName : booking?.customer?.name ?? 'Customer';
    final qty = quantity.isNotEmpty ? quantity : '${booking?.gasKg ?? 0} kg';
    final addr = booking?.address ?? 'Delivery location';

    return GestureDetector(
      onTap: () => context.push('/delivery/order/$id'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.input,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_gas_station, color: AppColors.brandYellow),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
                      Text(addr, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(
                  payout.isNotEmpty ? payout : '—',
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _chip(Icons.local_gas_station, fuelType.isNotEmpty ? fuelType : 'Gas'),
                const SizedBox(width: 8),
                _chip(Icons.water_drop_outlined, qty),
                const Spacer(),
                if (distance.isNotEmpty)
                  Text('$distance • $eta', style: AppTextStyles.caption.copyWith(fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.input,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.brandGold),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10, color: AppColors.white)),
        ],
      ),
    );
  }
}
