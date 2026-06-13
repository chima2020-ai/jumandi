import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const DeliveryAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Delivery History', style: AppTextStyles.heading.copyWith(fontSize: 24)),
          const SizedBox(height: 6),
          Text(
            'Review your completed fuel deliveries and earnings metrics.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL EARNINGS THIS WEEK', style: AppTextStyles.label),
                      const SizedBox(height: 8),
                      Text(
                        '\$1,482.50',
                        style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 28),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('GALLONS PUMPED', style: AppTextStyles.label),
                    const SizedBox(height: 8),
                    Text('2,840 Ga', style: AppTextStyles.headingSmall.copyWith(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _dateHeader('TODAY, OCT 24'),
          _deliveryItem('Industrial Logistics Hub', '14:22 PM • 250 Gallons', '\$145.20'),
          _deliveryItem('Port Authority Terminal 4', '09:15 AM • 800 Gallons', '\$412.00'),
          const SizedBox(height: 16),
          _dateHeader('YESTERDAY, OCT 23'),
          _deliveryItem('Summit Construction Site', '16:45 PM • 320 Gallons', '\$188.50'),
          _deliveryItem('Metro Fleet Maintenance', '11:30 AM • 600 Gallons', '\$305.00'),
          _deliveryItem('Rail Cargo East Yard', '08:00 AM • 180 Gallons', '\$220.75'),
        ],
      ),
    );
  }

  Widget _dateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: AppTextStyles.label.copyWith(fontSize: 10)),
    );
  }

  Widget _deliveryItem(String location, String details, String earnings) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_gas_station, color: AppColors.brandYellow, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(details, style: AppTextStyles.caption),
              ],
            ),
          ),
          Text(
            earnings,
            style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
