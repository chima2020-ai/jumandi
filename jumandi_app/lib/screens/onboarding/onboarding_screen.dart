import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_assets.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../widgets/common/auth_hero_banner.dart';
import '../../widgets/common/jumandi_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    AppAssets.loginLogo,
                    height: 36,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Skip',
                      style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        AppAssets.onboardingHero,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.85),
                              ],
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(width: 3, height: 36, color: AppColors.brandYellow),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SYSTEM STATUS',
                                    style: AppTextStyles.label.copyWith(color: AppColors.brandYellow),
                                  ),
                                  Text(
                                    'Network Active',
                                    style: AppTextStyles.headingSmall.copyWith(fontSize: 14),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.wifi, color: AppColors.brandYellow),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      'ENERGY ON\nDEMAND',
                      style: AppTextStyles.heading.copyWith(fontSize: 30, height: 1.1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Jumandi is redefining gas delivery. Experience precise, on-demand refueling delivered directly to your door, 24/7.',
                      style: AppTextStyles.body,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: const [
                        FeatureCard(icon: Icons.bolt, title: 'Instant Access', subtitle: 'Tap to Refuel'),
                        SizedBox(width: 12),
                        FeatureCard(icon: Icons.precision_manufacturing, title: 'Mission Ready', subtitle: '24/7 Grid Support'),
                      ],
                    ),
                    const Spacer(),
                    JumandiPrimaryButton(
                      label: 'NEXT DESTINATION',
                      icon: Icons.arrow_forward,
                      onPressed: () => context.go('/login'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.brandYellow,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _dot(false),
                        const SizedBox(width: 6),
                        _dot(false),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: active ? AppColors.brandYellow : AppColors.input,
          shape: BoxShape.circle,
        ),
      );
}
