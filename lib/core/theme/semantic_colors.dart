import 'package:flutter/material.dart';

/// Brand semantic colors that sit outside Material's seed-derived scheme:
/// a completed set is success-green, a missed one is error-red — deliberately
/// distinct from the gold accent so "done" never reads as "brand color".
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.failure,
    required this.onFailure,
  });

  final Color success;
  final Color failure;
  final Color onFailure;

  /// The brand values (identical in light and dark; both read well on either
  /// ground). Used as the registered theme extension and as a safe fallback.
  static const brand = SemanticColors(
    success: Color(0xFF1F9D5B),
    // Deep red — pushed away from the brand orange (35° hue) so a missed set
    // reads as a distinct state instead of clashing with the accent.
    failure: Color(0xFFC62828),
    onFailure: Color(0xFFFFFFFF),
  );

  /// Reads the extension off [context], falling back to [brand] when a widget
  /// is built under a theme that didn't register it (e.g. a bare test harness).
  static SemanticColors of(BuildContext context) =>
      Theme.of(context).extension<SemanticColors>() ?? brand;

  @override
  SemanticColors copyWith({
    Color? success,
    Color? failure,
    Color? onFailure,
  }) =>
      SemanticColors(
        success: success ?? this.success,
        failure: failure ?? this.failure,
        onFailure: onFailure ?? this.onFailure,
      );

  @override
  SemanticColors lerp(covariant SemanticColors? other, double t) {
    if (other == null) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      failure: Color.lerp(failure, other.failure, t)!,
      onFailure: Color.lerp(onFailure, other.onFailure, t)!,
    );
  }
}
