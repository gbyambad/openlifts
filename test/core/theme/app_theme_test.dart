import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/theme/app_theme.dart';
import 'package:openlifts/core/theme/brand_colors.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';

void main() {
  test('themes use the warm ink/paper grounds, not a cold gray', () {
    expect(AppTheme.dark.scaffoldBackgroundColor, BrandColors.brand.ink);
    expect(AppTheme.light.scaffoldBackgroundColor, BrandColors.brand.paper);
  });

  test('both themes register the brand and semantic color extensions', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.extension<BrandColors>(), isNotNull);
      expect(theme.extension<SemanticColors>(), isNotNull);
    }
  });

  test('the app bar title always reads (pinned to onSurface, no white-out)',
      () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final bar = theme.appBarTheme;
      // Title colour matches the scheme's onSurface -> readable on the ground.
      expect(bar.titleTextStyle?.color, theme.colorScheme.onSurface);
      expect(bar.foregroundColor, theme.colorScheme.onSurface);
      // Bar blends with the scaffold; no elevation tint that washes it white.
      expect(bar.backgroundColor, theme.scaffoldBackgroundColor);
      expect(bar.surfaceTintColor, Colors.transparent);
    }
  });

  test('primary is the vivid brand orange, not the fromSeed muted tone', () {
    // Pinned in both modes so the app accent matches the raw-seed logo, not the
    // chroma-reduced tone fromSeed would otherwise derive.
    expect(AppTheme.light.colorScheme.primary, const Color(0xFFD35400));
    expect(AppTheme.dark.colorScheme.primary, const Color(0xFFFF9500));
  });

  test('selected chips, segments, and focused inputs carry the brand primary',
      () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      // Chips select in brand orange, not M3's default secondary-container.
      expect(theme.chipTheme.checkmarkColor, theme.colorScheme.primary);
      // Segmented buttons select in brand orange too.
      final segForeground = theme.segmentedButtonTheme.style?.foregroundColor
          ?.resolve({WidgetState.selected});
      expect(segForeground, theme.colorScheme.primary);
      // Idle input borders soften to outlineVariant; focus brings in primary.
      final enabled = theme.inputDecorationTheme.enabledBorder;
      final focused = theme.inputDecorationTheme.focusedBorder;
      expect(
        (enabled! as OutlineInputBorder).borderSide.color,
        theme.colorScheme.outlineVariant,
      );
      expect(
        (focused! as OutlineInputBorder).borderSide.color,
        theme.colorScheme.primary,
      );
    }
  });
}
