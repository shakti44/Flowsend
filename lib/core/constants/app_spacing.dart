/// Spacing constants from the Kinetic Obsidian design system.
/// All based on a 4px (0.25rem) harmonic grid.
abstract final class AppSpacing {
  static const double xs = 4.0;   // space-xs: 0.25rem
  static const double sm = 8.0;   // space-sm: 0.5rem
  static const double md = 16.0;  // space-md: 1rem  (gutter)
  static const double base = 16.0; // alias for md
  static const double lg = 24.0;  // space-lg: 1.5rem
  static const double xl = 40.0;  // space-xl: 2.5rem
  static const double full = 9999.0; // pill radius
  static const double margin = 20.0;        // 1.25rem
  static const double marginTablet = 32.0;  // 2rem
  static const double marginDesktop = 48.0; // 3rem
  static const double gutterDesktop = 24.0; // 1.5rem
}

/// Border-radius constants from the Kinetic Obsidian design system.
abstract final class AppRadius {
  static const double sm = 8.0;    // 0.5rem
  static const double base = 16.0; // 1rem (DEFAULT)
  static const double md = 24.0;   // 1.5rem
  static const double lg = 32.0;   // 2rem
  static const double xl = 48.0;   // 3rem
  static const double full = 9999.0; // pill / full-round
}

