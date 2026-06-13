import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/booking_model.dart';
import '../../providers/app_providers.dart';
import '../../services/api_service.dart';
import '../../services/call_service.dart';
import '../../widgets/common/jumandi_app_bar.dart';

class HomeMapScreen extends StatefulWidget {
  const HomeMapScreen({super.key});

  @override
  State<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends State<HomeMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().loadCustomerBookings();
    });
  }

  Future<void> _callDriver() async {
    final booking = context.read<BookingProvider>().activeCustomerBooking;
    if (booking == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active delivery to call yet')),
      );
      return;
    }
    try {
      await context.read<CallService>().startCall(booking.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBooking = context.watch<BookingProvider>().activeCustomerBooking;

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(showMenu: false),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const Spacer(),
            _fleetCard(context, activeBooking),
            const SizedBox(height: 12),
            _quickRefuelCard(context),
          ],
        ),
      ),
    );
  }

  Widget _fleetCard(BuildContext context, BookingModel? activeBooking) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ACTIVE FLEET', style: AppTextStyles.label),
                    Text(
                      activeBooking != null ? 'Booking #${activeBooking.id}' : 'No active delivery',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.brandGold,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('STATUS', style: AppTextStyles.label),
                  Text(
                    activeBooking?.status.label ?? 'IDLE',
                    style: AppTextStyles.headingSmall,
                  ),
                ],
              ),
            ],
          ),
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
              const SizedBox(width: 10),
              Material(
                color: AppColors.input,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: activeBooking != null ? _callDriver : null,
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.phone,
                      color: activeBooking != null ? AppColors.brandGold : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickRefuelCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandYellowBright,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppColors.black, shape: BoxShape.circle),
            child: const Icon(Icons.speed, color: AppColors.brandYellow, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Need a quick refuel?', style: AppTextStyles.headingSmall.copyWith(color: AppColors.black, fontSize: 14)),
                Text('Standard response: 20 mins', style: AppTextStyles.caption.copyWith(color: AppColors.black.withValues(alpha: 0.7))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.go('/home/booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.quickRefuelButton,
              foregroundColor: AppColors.brandGold,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('REQUEST\nREFUEL', style: AppTextStyles.button.copyWith(color: AppColors.brandGold, fontSize: 9), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
