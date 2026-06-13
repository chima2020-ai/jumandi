import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/delivery_bottom_nav.dart';
import '../../widgets/common/jumandi_button.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'Marcus V. Sterling';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const DeliveryAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brandYellow, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandYellow.withValues(alpha: 0.35),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      color: AppColors.card,
                      child: const Icon(Icons.engineering, size: 50, color: AppColors.brandGold),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.military_tech, color: AppColors.black, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('UNIT 742', style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 26, letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('HEAVY TANKER SPECIALIST', style: AppTextStyles.label.copyWith(color: AppColors.white, letterSpacing: 1.5)),
            const SizedBox(height: 24),
            _earningsCard(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _miniStat('RATINGS', '4.98 ★', '500+ Deliveries')),
                const SizedBox(width: 12),
                Expanded(child: _miniStat('SAFETY', '100%', 'Zero Incidents', highlight: true)),
              ],
            ),
            const SizedBox(height: 16),
            _detailSection(
              icon: Icons.local_gas_station,
              title: 'Vehicle Details',
              showEdit: true,
              rows: const {
                'ASSIGNED UNIT': 'Tanker #42',
                'MODEL': 'Kenworth T680 Fueler',
                'PAYLOAD CAPACITY': '9,000 Gallons',
                'INSPECTION STATUS': 'CERTIFIED',
              },
            ),
            const SizedBox(height: 12),
            _detailSection(
              icon: Icons.person_outline,
              title: 'Personal Info',
              rows: {
                'FULL NAME': name,
                'EMPLOYEE ID': 'FS-742-ALPHA',
                'CONTACT': auth.user?.phone ?? '+1 (555) 942-0192',
              },
            ),
            const SizedBox(height: 24),
            JumandiPrimaryButton(
              label: 'GO OFF DUTY',
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _earningsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
              Text('TOTAL EARNINGS', style: AppTextStyles.label),
              Icon(Icons.payments_outlined, color: AppColors.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$42,850.24',
            style: AppTextStyles.heading.copyWith(color: AppColors.brandYellow, fontSize: 30),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 5,
              backgroundColor: AppColors.input,
              color: AppColors.brandYellow,
            ),
          ),
          const SizedBox(height: 8),
          Text('75% of monthly target achieved', style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, String sub, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.heading.copyWith(
              fontSize: 22,
              color: highlight ? AppColors.brandYellow : AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(sub, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _detailSection({
    required IconData icon,
    required String title,
    required Map<String, String> rows,
    bool showEdit = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.brandGold, size: 20),
              const SizedBox(width: 10),
              Text(title, style: AppTextStyles.headingSmall.copyWith(fontSize: 15)),
              const Spacer(),
              if (showEdit)
                Text('EDIT', style: AppTextStyles.button.copyWith(color: AppColors.brandYellow, fontSize: 11)),
            ],
          ),
          const Divider(color: AppColors.inputBorder, height: 24),
          ...rows.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Text(e.key, style: AppTextStyles.caption.copyWith(fontSize: 10)),
                    const Spacer(),
                    if (e.key == 'INSPECTION STATUS') ...[
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(color: AppColors.brandYellow, shape: BoxShape.circle),
                      ),
                    ],
                    Text(
                      e.value,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
