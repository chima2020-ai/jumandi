import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/delivery_bottom_nav.dart';

class DeliveryDashboardScreen extends StatelessWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const DeliveryAppBar(),
      body: ListView(
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
                Text('ACTIVE SHIFT', style: AppTextStyles.label),
                const SizedBox(height: 8),
                Text(
                  '08h 42m',
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.brandYellow,
                    fontSize: 36,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, color: AppColors.brandYellow, size: 16),
                    const SizedBox(width: 6),
                    Text('System Online', style: AppTextStyles.caption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statCard(
                  'Total Orders',
                  '142',
                  '+12% vs last week',
                  highlightSub: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _statCard('Efficiency', '98.4%', null, showBar: true),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Quick Actions', style: AppTextStyles.headingSmall),
          const SizedBox(height: 12),
          _actionTile(Icons.assignment_outlined, 'View pending requests', '3 new orders waiting'),
          _actionTile(Icons.navigation_outlined, 'Active delivery', 'Tanker #0842 — in transit'),
          _actionTile(Icons.chat_bubble_outline, 'Customer messages', '1 unread message'),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, String? sub, {bool highlightSub = false, bool showBar = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading.copyWith(fontSize: 28)),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub,
              style: AppTextStyles.caption.copyWith(
                color: highlightSub ? AppColors.brandYellow : AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
          if (showBar) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.984,
                minHeight: 4,
                backgroundColor: AppColors.input,
                color: AppColors.brandYellow,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.input,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brandGold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 14)),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
