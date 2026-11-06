import 'package:flutter/material.dart';

class AppColors {
  static const indigo = Color(0xFF1F2A5C);
  static const indigoDeep = Color(0xFF141C42);
  static const wheat = Color(0xFFF2B84B);
  static const paper = Color(0xFFF5F6FA);
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: brightness,
  ).copyWith(secondary: AppColors.wheat);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppColors.indigoDeep : AppColors.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.indigoDeep : AppColors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.wheat,
      foregroundColor: AppColors.indigoDeep,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.wheat,
    ),
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}
