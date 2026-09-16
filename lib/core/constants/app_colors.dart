import 'package:flutter/material.dart';

/// Kinetic Obsidian design system colors.
/// All values extracted directly from the Stitch DESIGN.md export.
abstract final class AppColors {
  // ─── Surface Tiers ────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF0F131C);
  static const Color surfaceDim = Color(0xFF0F131C);
  static const Color surfaceContainerLowest = Color(0xFF0A0E17);
  static const Color surfaceContainerLow = Color(0xFF181B25);
  static const Color surfaceContainer = Color(0xFF1C1F29);
  static const Color surfaceContainerHigh = Color(0xFF262A34);
  static const Color surfaceContainerHighest = Color(0xFF31353F);
  static const Color surfaceBright = Color(0xFF353943);
  static const Color background = Color(0xFF0F131C);

  // ─── Primary ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFFB3C5FF);
  static const Color onPrimary = Color(0xFF002B75);
  static const Color primaryContainer = Color(0xFF0066FF);
  static const Color onPrimaryContainer = Color(0xFFF8F7FF);
  static const Color primaryFixedDim = Color(0xFFB3C5FF);
  static const Color primaryFixed = Color(0xFFDAE1FF);
  static const Color onPrimaryFixed = Color(0xFF001849);
  static const Color onPrimaryFixedVariant = Color(0xFF003FA4);
  static const Color inversePrimary = Color(0xFF0054D6);

  // ─── Secondary (Kinetic Cyan) ─────────────────────────────────────────────
  static const Color secondary = Color(0xFFA5E7FF);
  static const Color onSecondary = Color(0xFF003543);
  static const Color secondaryContainer = Color(0xFF00D2FF);
  static const Color onSecondaryContainer = Color(0xFF00566A);
  static const Color secondaryFixedDim = Color(0xFF47D6FF);
  static const Color secondaryFixed = Color(0xFFB6EBFF);
  static const Color onSecondaryFixed = Color(0xFF001F28);
  static const Color onSecondaryFixedVariant = Color(0xFF004E60);

  // ─── Tertiary (Electric Indigo) ───────────────────────────────────────────
  static const Color tertiary = Color(0xFFC0C1FF);
  static const Color onTertiary = Color(0xFF1000A9);
  static const Color tertiaryContainer = Color(0xFF5D60EB);
  static const Color onTertiaryContainer = Color(0xFFFAF6FF);
  static const Color tertiaryFixedDim = Color(0xFFC0C1FF);
  static const Color tertiaryFixed = Color(0xFFE1E0FF);
  static const Color onTertiaryFixed = Color(0xFF07006C);
  static const Color onTertiaryFixedVariant = Color(0xFF2F2EBE);

  // ─── Error ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ─── On-Surface ───────────────────────────────────────────────────────────
  static const Color onSurface = Color(0xFFDFE2EF);
  static const Color onSurfaceVariant = Color(0xFFC2C6D8);
  static const Color inverseSurface = Color(0xFFDFE2EF);
  static const Color inverseOnSurface = Color(0xFF2C303A);

  // ─── Outline ──────────────────────────────────────────────────────────────
  static const Color outline = Color(0xFF8C90A1);
  static const Color outlineVariant = Color(0xFF424656);

  // ─── Brand Glow Colors (ambient shadows / halos) ──────────────────────────
  /// Cyan glow for active transfers: rgba(0, 210, 255, 0.35)
  static const Color transferGlow = Color(0x5900D2FF);

  /// Security verified emerald: #10B981
  static const Color securityGreen = Color(0xFF10B981);
  static const Color securityGreenAmbient = Color(0x2610B981);

  /// Error / interrupted: #EF4444
  static const Color warningRed = Color(0xFFEF4444);

  // ─── Glassmorphism Fills ──────────────────────────────────────────────────
  /// Glass Tier 1: rgba(17, 24, 39, 0.72)
  static const Color glassTier1 = Color(0xB8111827);

  /// Glass Tier 2: rgba(30, 41, 59, 0.8)
  static const Color glassTier2 = Color(0xCC1E293B);

  // ─── Gradient Stops ───────────────────────────────────────────────────────
  static const List<Color> brandGradient = [
    Color(0xFF00D2FF), // cyan
    Color(0xFF0066FF), // cobalt
    Color(0xFF6366F1), // indigo
  ];

  static const List<Color> primaryButtonGradient = [
    Color(0xFF0066FF),
    Color(0xFF5D60EB),
  ];

  static const List<Color> transferRingGradient = [
    Color(0xFF0066FF),
    Color(0xFF00D2FF),
    Color(0xFFA5E7FF),
  ];
}
