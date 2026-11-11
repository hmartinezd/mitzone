import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient primaryBrand = LinearGradient(
    colors: [AppColors.primary, AppColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.secondary, AppColors.accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient backgroundAtmospheric = RadialGradient(
    colors: [
      Color(0xFF1A1F35), // Slightly lighter deep navy
      AppColors.background,
    ],
    center: Alignment.topCenter,
    radius: 1.5,
  );
}
