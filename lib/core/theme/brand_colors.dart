import 'package:flutter/material.dart';

/// Named brand tokens that live alongside (not inside) Material's seed-derived
/// scheme: the two warm neutral grounds and the deep accent variant (Apple
/// orange). The `gold*` field names are historical; the values are the brand
/// orange. Kept as a single source of truth so components can reach for them
/// directly.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.goldDeep,
    required this.ink,
    required this.paper,
  });

  /// Pressed states; gold text or icons on light grounds.
  final Color goldDeep;

  /// Warm near-black — dark ground and text.
  final Color ink;

  /// Warm off-white — light ground.
  final Color paper;

  static const brand = BrandColors(
    goldDeep: Color(0xFFC2700A),
    ink: Color(0xFF1A1712),
    paper: Color(0xFFF5F2EC),
  );

  @override
  BrandColors copyWith({
    Color? goldDeep,
    Color? ink,
    Color? paper,
  }) =>
      BrandColors(
        goldDeep: goldDeep ?? this.goldDeep,
        ink: ink ?? this.ink,
        paper: paper ?? this.paper,
      );

  @override
  BrandColors lerp(covariant BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      goldDeep: Color.lerp(goldDeep, other.goldDeep, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
    );
  }
}
