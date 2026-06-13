import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/jumandi_app_bar.dart';

class HomeMapScreen extends StatelessWidget {
  const HomeMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(showMenu: false),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            const Spacer(),
            _fleetCard(context),
            const SizedBox(height: 12),
            _quickRefuelCard(context),
          ],
        ),
      ),
    );
  }

  Widget _fleetCard(BuildContext context) {
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
                    Text('Tanker #0842', style: AppTextStyles.heading.copyWith(color: AppColors.brandGold, fontSize: 22)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('ARRIVAL', style: AppTextStyles.label),
                  Text('12 MIN', style: AppTextStyles.headingSmall),
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
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.headset_mic, color: AppColors.brandGold),
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
