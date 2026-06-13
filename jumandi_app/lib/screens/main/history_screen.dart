import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/jumandi_app_bar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadCustomerBookings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BookingProvider>();
    final bookings = provider.bookings;
    final completed = provider.completedBookings;
    final totalKg = provider.totalGasKgDelivered;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(),
      body: RefreshIndicator(
        onRefresh: provider.loadCustomerBookings,
        color: AppColors.brandYellow,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(child: _statCard('TOTAL GAS', totalKg.toStringAsFixed(1), 'kg')),
                const SizedBox(width: 12),
                Expanded(child: _statCard('ORDERS', '${completed.length}', null)),
              ],
            ),
            const SizedBox(height: 28),
            Text('Order History', style: AppTextStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 16),
            if (provider.loading && bookings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(color: AppColors.brandYellow),
                ),
              )
            else if (provider.error != null && bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(provider.error!, style: AppTextStyles.body.copyWith(color: Colors.redAccent)),
              )
            else if (bookings.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No bookings yet. Book gas from the Booking tab.', style: AppTextStyles.body),
              )
            else
              ...bookings.map(_orderCard),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, String? unit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: AppColors.brandYellow, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 26)),
              if (unit != null) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(unit, style: AppTextStyles.caption.copyWith(color: AppColors.white)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _orderCard(BookingModel booking) {
    final date = DateFormat('MMM d, yyyy • h:mm a').format(booking.createdAt.toLocal());
    final statusColor = booking.status == BookingStatus.delivered
        ? AppColors.brandYellow
        : AppColors.textMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${booking.id}',
                style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: statusColor, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      booking.status.label.toUpperCase(),
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(booking.address, style: AppTextStyles.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          Row(
            children: [
              _dataCol('GAS', '${booking.gasKg.toStringAsFixed(1)} kg'),
              _dataCol('DRIVER', booking.deliveryAgent?.name ?? '—'),
              _dataCol('NOTES', booking.notes?.isNotEmpty == true ? 'Yes' : '—'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.headingSmall.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
