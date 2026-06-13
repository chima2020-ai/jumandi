import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class LoadingSplashScreen extends StatefulWidget {
  const LoadingSplashScreen({super.key});

  @override
  State<LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<LoadingSplashScreen> {
  double _progress = 0.34;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (_progress >= 1.0) {
        t.cancel();
        if (mounted) context.go('/onboarding');
        return;
      }
      setState(() => _progress += 0.02);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
              children: [
                const Spacer(flex: 3),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.brandYellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.local_gas_station, size: 36, color: AppColors.black),
                ),
                const SizedBox(height: 20),
                Text(
                  'JUMANDI',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 44,
                    color: AppColors.brandYellow,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ON-DEMAND ENERGY',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.white,
                    letterSpacing: 4,
                    fontSize: 12,
                  ),
                ),
                const Spacer(flex: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 3,
                          backgroundColor: AppColors.input,
                          color: AppColors.brandYellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('INITIALIZING SYSTEMS', style: AppTextStyles.caption),
                          Text(
                            '${(_progress * 100).toInt()}%',
                            style: AppTextStyles.caption.copyWith(color: AppColors.brandYellow),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
      ),
    );
  }
}
