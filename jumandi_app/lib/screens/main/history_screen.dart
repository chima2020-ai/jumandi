import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/jumandi_app_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _statCard('TOTAL FUEL', '1,482', 'Gal')),
              const SizedBox(width: 12),
              Expanded(child: _statCard('TOTAL SPEND', '\$ 6,240', null)),
            ],
          ),
          const SizedBox(height: 28),
          Text('Order History', style: AppTextStyles.heading.copyWith(fontSize: 22)),
          const SizedBox(height: 16),
          _orderCard('#aa-9821', 'Oct 24, 2023 • 09:15 AM', 'Diesel Pro', '45 Gal', '\$189.00'),
          _orderCard('#aa-9819', 'Oct 22, 2023 • 14:30 PM', 'Premium', '30 Gal', '\$123.60'),
          _orderCard('#aa-9815', 'Oct 20, 2023 • 11:00 AM', 'Gas', '12 kg', '\$54.60'),
        ],
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

  Widget _orderCard(String id, String date, String type, String volume, String total) {
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
              Text(id, style: AppTextStyles.headingSmall.copyWith(color: AppColors.brandYellow, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.input,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: AppColors.brandYellow, size: 14),
                    const SizedBox(width: 4),
                    Text('COMPLETED', style: AppTextStyles.label.copyWith(fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(date, style: AppTextStyles.caption),
          const SizedBox(height: 16),
          Row(
            children: [
              _dataCol('TYPE', type),
              _dataCol('VOLUME', volume),
              _dataCol('TOTAL', total, highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dataCol(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 14,
              color: highlight ? AppColors.brandYellow : AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}
