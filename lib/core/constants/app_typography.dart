import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography constants from the Kinetic Obsidian design system.
/// Headlines/body use Plus Jakarta Sans; labels/telemetry use Inter.
abstract final class AppTypography {
  // ─── Plus Jakarta Sans — Headlines ────────────────────────────────────────
  static TextStyle headlineXl = GoogleFonts.plusJakartaSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    height: 48 / 40,
    letterSpacing: -0.03 * 40,
  );

  static TextStyle headlineXlMobile = GoogleFonts.plusJakartaSans(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 38 / 30,
    letterSpacing: -0.025 * 30,
  );

  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.02 * 32,
  );

  static TextStyle headlineLgMobile = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.015 * 24,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.015 * 22,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.01 * 18,
  );

  // ─── Plus Jakarta Sans — Body ──────────────────────────────────────────────
  static TextStyle bodyLg = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: -0.005 * 16,
  );

  static TextStyle bodyMd = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static TextStyle bodySm = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.01 * 12,
  );

  // ─── Inter — Labels ────────────────────────────────────────────────────────
  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 18 / 14,
    letterSpacing: 0.01 * 14,
  );

  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.02 * 12,
  );

  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.04 * 11,
  );

  // ─── Inter — Telemetry (tabular numbers for live data) ────────────────────
  static TextStyle telemetryData = GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 16 / 13,
    letterSpacing: -0.01 * 13,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
