import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/auth_hero_banner.dart';
import '../../widgets/common/jumandi_app_bar.dart';
import '../../widgets/common/jumandi_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?.name ?? 'Alex Sterling';

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: const JumandiAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.brandYellow, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandYellow.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Container(
                      color: AppColors.card,
                      child: const Icon(Icons.person, size: 60, color: AppColors.brandGold),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.brandYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: AppColors.black, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(name, style: AppTextStyles.heading.copyWith(fontSize: 24)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.brandYellow.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.military_tech, color: AppColors.brandYellow, size: 18),
                  const SizedBox(width: 8),
                  Text('Premium Member', style: AppTextStyles.button.copyWith(color: AppColors.brandYellow, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SettingsTile(
              icon: Icons.settings,
              title: 'Account Settings',
              subtitle: 'Update personal details and preferences',
            ),
            SettingsTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payment Methods',
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.input,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('VISA', style: AppTextStyles.label.copyWith(color: AppColors.white, fontSize: 10)),
                    ),
                    const SizedBox(width: 12),
                    Text('•••• 4242', style: AppTextStyles.body.copyWith(color: AppColors.white)),
                    const Spacer(),
                    Text('Default', style: AppTextStyles.button.copyWith(color: AppColors.brandYellow, fontSize: 11)),
                  ],
                ),
              ),
            ),
            SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Security & Privacy',
              subtitle: '2FA, Biometrics, and Data management',
            ),
            SettingsTile(
              icon: Icons.notifications_none,
              title: 'Notification Preferences',
              subtitle: 'Manage push and email alerts',
            ),
            const SizedBox(height: 8),
            JumandiOutlineButton(
              label: 'Sign Out',
              icon: Icons.logout,
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
}
