import 'package:flutter/material.dart';
import 'package:openlifts/core/theme/brand_colors.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';

/// OpenLifts brand theme — gold on a warm-dark ground.
///
/// The scheme derives from the gold brand token via Material 3's seed (which
/// generates accessible on-gold contrast), then applies the warm neutral
/// grounds and gold-deep pressed feedback from [BrandColors].
abstract final class AppTheme {
  /// Brand orange (primary) — Apple's system/Calculator orange. Vibrant on the
  /// dark ground; on a light ground the same bright orange fails text contrast,
  /// so light mode uses the deeper [_orangeLight] variant (Apple ships
  /// different light/dark oranges too).
  static const _seed = Color(0xFFFF9500);

  /// Deeper orange for light mode: readable as text/icons on the warm paper
  /// ground while still clearly "brand orange", not the muddy brown that
  /// `ColorScheme.fromSeed` derives from the bright seed.
  static const _orangeLight = Color(0xFFD35400);

  static ThemeData get light =>
      _build(Brightness.light, BrandColors.brand.paper);

  static ThemeData get dark => _build(Brightness.dark, BrandColors.brand.ink);

  /// A deliberate Barlow type scale — headings tightened and bolder, labels
  /// given weight and tracking, and tabular figures everywhere so weights and
  /// reps line up in columns. Keeps the M3 sizes; only weight/spacing/figures
  /// are tuned, so layouts don't shift.
  static TextTheme _textTheme(Brightness brightness) {
    final typo = Typography.material2021();
    final base = brightness == Brightness.dark ? typo.white : typo.black;
    const tabular = [FontFeature.tabularFigures()];
    TextStyle? tune(TextStyle? s, {FontWeight? weight, double? spacing}) =>
        s?.copyWith(
          fontFamily: 'Barlow',
          fontWeight: weight,
          letterSpacing: spacing,
          fontFeatures: tabular,
        );
    return base.copyWith(
      headlineMedium:
          tune(base.headlineMedium, weight: FontWeight.w700, spacing: -0.3),
      headlineSmall:
          tune(base.headlineSmall, weight: FontWeight.w700, spacing: -0.2),
      titleLarge: tune(base.titleLarge, weight: FontWeight.w700, spacing: -0.1),
      titleMedium: tune(base.titleMedium, weight: FontWeight.w600),
      titleSmall: tune(base.titleSmall, weight: FontWeight.w600),
      bodyLarge: tune(base.bodyLarge),
      bodyMedium: tune(base.bodyMedium),
      bodySmall: tune(base.bodySmall),
      labelLarge: tune(base.labelLarge, weight: FontWeight.w600, spacing: 0.1),
      labelMedium:
          tune(base.labelMedium, weight: FontWeight.w600, spacing: 0.3),
      labelSmall: tune(base.labelSmall, weight: FontWeight.w700, spacing: 0.5),
    );
  }

  static ThemeData _build(Brightness brightness, Color ground) {
    final isLight = brightness == Brightness.light;
    var scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    // `fromSeed` derives a chroma-reduced tone for the primary, not the seed
    // itself — so accents (active states, buttons, weights) come out muted
    // while the logo, drawn with the raw seed, stays vivid. Pin the primary to
    // the brand orange in both modes so they match: the deeper [_orangeLight]
    // on the light paper ground (readable as text), the full [_seed] on dark.
    // onPrimary is chosen for legibility on that fill (near-black reads on the
    // bright orange; white on the deeper light-mode orange).
    scheme = isLight
        ? scheme.copyWith(primary: _orangeLight, onPrimary: Colors.white)
        : scheme.copyWith(primary: _seed, onPrimary: const Color(0xFF241400));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: 'Barlow',
      textTheme: _textTheme(brightness),
      scaffoldBackgroundColor: ground, // warm ink / paper, never a cold gray
      extensions: const [SemanticColors.brand, BrandColors.brand],
      // Selected filter/choice chips read in the brand orange (a subtle tint +
      // orange check), not M3's default muted secondary-container brown.
      chipTheme: ChipThemeData(
        selectedColor: scheme.primary.withValues(alpha: 0.22),
        checkmarkColor: scheme.primary,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      // Soften input outlines to the low-contrast variant when idle; focus
      // still brings in the primary. Keeps text fields calm, not boxy.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      // Selected segment reads in the brand orange (a subtle tint + orange
      // label/check), not M3's default secondary-container brown.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary.withValues(alpha: 0.22)
                : null,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant),
          ),
          textStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontFamily: 'Barlow',
              fontSize: 14,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        // Blend the bar with the scaffold ground and kill the M3 elevation tint
        // so a scrolled header never washes out to near-white (which hid the
        // title). Title colour is pinned to onSurface so it always reads.
        backgroundColor: ground,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: scheme.onSurface,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withValues(alpha: 0.22),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 13,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 26,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.pressed)
                ? BrandColors.brand.goldDeep.withValues(alpha: 0.2)
                : null,
          ),
        ),
      ),
    );
  }
}
