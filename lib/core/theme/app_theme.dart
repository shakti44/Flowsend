import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';

/// Kinetic Obsidian dark theme for FlowSend.
/// Only dark mode is implemented in Phase 1 (as per design).
abstract final class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        surfaceContainerLowest: AppColors.surfaceContainerLowest,
        surfaceContainerLow: AppColors.surfaceContainerLow,
        surfaceContainer: AppColors.surfaceContainer,
        surfaceContainerHigh: AppColors.surfaceContainerHigh,
        surfaceContainerHighest: AppColors.surfaceContainerHighest,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.8),
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        titleTextStyle: AppTypography.headlineSm.copyWith(
          color: AppColors.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceContainerLowest.withValues(alpha: 0.85),
        indicatorColor: AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
        labelTextStyle: WidgetStateProperty.all(
          AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.secondary);
          }
          return const IconThemeData(color: AppColors.onSurfaceVariant);
        }),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryContainer,
          foregroundColor: AppColors.onPrimaryContainer,
          minimumSize: const Size(double.infinity, 52),
          shape: const StadiumBorder(),
          textStyle: AppTypography.labelLg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.onSurface,
          minimumSize: const Size(double.infinity, 48),
          shape: const StadiumBorder(),
          side: const BorderSide(color: AppColors.outlineVariant),
          textStyle: AppTypography.labelLg,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.headlineXl.copyWith(color: AppColors.onSurface),
        displayMedium: AppTypography.headlineLg.copyWith(color: AppColors.onSurface),
        displaySmall: AppTypography.headlineLgMobile.copyWith(color: AppColors.onSurface),
        headlineLarge: AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
        headlineMedium: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
        titleLarge: AppTypography.headlineSm.copyWith(color: AppColors.onSurface),
        titleMedium: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
        titleSmall: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
        bodyLarge: AppTypography.bodyLg.copyWith(color: AppColors.onSurface),
        bodyMedium: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        bodySmall: AppTypography.bodySm.copyWith(color: AppColors.onSurfaceVariant),
        labelLarge: AppTypography.labelLg.copyWith(color: AppColors.onSurface),
        labelMedium: AppTypography.labelMd.copyWith(color: AppColors.onSurfaceVariant),
        labelSmall: AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHighest,
        contentTextStyle: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.xl),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
