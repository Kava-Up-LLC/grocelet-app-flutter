import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: AppText.family,
        scaffoldBackgroundColor: AppColors.fridge,
        colorScheme: const ColorScheme.light(
          primary: AppColors.pine,
          onPrimary: AppColors.onColor,
          secondary: AppColors.denim,
          onSecondary: AppColors.onColor,
          surface: AppColors.paper,
          onSurface: AppColors.ink,
        ),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.pine),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: AppColors.ink,
          contentTextStyle: TextStyle(fontFamily: AppText.family, fontSize: 15, color: AppColors.onColor),
          behavior: SnackBarBehavior.floating,
        ),
        splashFactory: NoSplash.splashFactory,
      );
}
