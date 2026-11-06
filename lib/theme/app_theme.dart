import 'package:flutter/material.dart';

class AppColors {
  static const indigo = Color(0xFF1F2A5C);
  static const indigoDeep = Color(0xFF141C42);
  static const wheat = Color(0xFFF2B84B);
  static const paper = Color(0xFFF5F6FA);
  static const borderLight = Color(0xFFD8DBE8);
  static const borderDark = Color(0xFF2E3A6B);
  static const cardDark = Color(0xFF1B2550);
  static const mutedLight = Color(0xFF555555);
}

class AppRadius {
  static const card = 16.0;
  static const dialog = 20.0;
  static const field = 12.0;
}

ThemeData buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.indigo,
    brightness: brightness,
  );
  final scheme = base.copyWith(
    primary: isDark ? const Color(0xFFB9C6FF) : AppColors.indigo,
    onPrimary: isDark ? AppColors.indigoDeep : Colors.white,
    secondary: AppColors.wheat,
    onSecondary: AppColors.indigoDeep,
    onSurface: isDark ? const Color(0xFFEDEFF7) : const Color(0xFF161A2B),
    onSurfaceVariant: isDark ? const Color(0xFFB7BDD6) : AppColors.mutedLight,
    outline: isDark ? AppColors.borderDark : AppColors.borderLight,
    outlineVariant: isDark ? AppColors.borderDark : AppColors.borderLight,
  );

  final cardColor = isDark ? AppColors.cardDark : Colors.white;
  final cardBorder = isDark ? AppColors.borderDark : AppColors.borderLight;
  final fieldFill = isDark ? const Color(0xFF1E2853) : Colors.white;

  final textTheme = ThemeData(brightness: brightness, useMaterial3: true)
      .textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
      .copyWith(
        headlineSmall: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.2,
          color: scheme.onSurface,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: scheme.onSurface,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: scheme.onSurface,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: scheme.onSurface,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.35,
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: scheme.onSurface,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurfaceVariant,
        ),
      );

  final outlineBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
    borderSide: BorderSide(color: cardBorder),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: isDark ? AppColors.indigoDeep : AppColors.paper,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: BorderSide(color: cardBorder),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: textTheme.bodyMedium,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: outlineBorder,
      enabledBorder: outlineBorder,
      disabledBorder: outlineBorder,
      focusedBorder: outlineBorder.copyWith(
        borderSide: BorderSide(
          color: isDark ? AppColors.wheat : AppColors.indigo,
          width: 1.6,
        ),
      ),
      errorBorder: outlineBorder.copyWith(
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: outlineBorder.copyWith(
        borderSide: BorderSide(color: scheme.error, width: 1.6),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      floatingLabelStyle: textTheme.labelLarge?.copyWith(
        color: isDark ? AppColors.wheat : AppColors.indigo,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.wheat,
        foregroundColor: AppColors.indigoDeep,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge?.copyWith(color: AppColors.indigoDeep),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? AppColors.wheat : AppColors.indigo,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: textTheme.labelLarge,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.wheat,
      foregroundColor: AppColors.indigoDeep,
      elevation: 1,
      focusElevation: 1,
      hoverElevation: 2,
      highlightElevation: 2,
      shape: const StadiumBorder(),
      extendedTextStyle: textTheme.labelLarge?.copyWith(
        color: AppColors.indigoDeep,
        fontWeight: FontWeight.w700,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: cardColor,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      textStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? const Color(0xFF2A3566) : AppColors.indigoDeep,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: cardColor,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF232E5C) : Colors.white,
      side: BorderSide(color: cardBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      labelStyle: textTheme.labelMedium,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
    ),
    dividerTheme: DividerThemeData(color: cardBorder, thickness: 1, space: 1),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: isDark ? AppColors.wheat : AppColors.indigo,
      selectionColor: AppColors.wheat.withValues(alpha: 0.35),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: isDark ? AppColors.wheat : AppColors.indigo,
    ),
  );
}
