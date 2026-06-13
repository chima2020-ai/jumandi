import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.black,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandYellow,
        secondary: AppColors.brandGold,
        surface: AppColors.card,
        error: AppColors.signOut,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.logo,
      ),
      dividerColor: AppColors.inputBorder,
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brandYellow,
        inactiveTrackColor: AppColors.input,
        thumbColor: AppColors.brandYellow,
        overlayColor: AppColors.brandYellow.withValues(alpha: 0.15),
      ),
    );
  }
}
