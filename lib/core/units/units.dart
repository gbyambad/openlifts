import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/loadable.dart';

const _lbPerKg = 2.2046226218;

double kgToLb(double kg) => kg * _lbPerKg;
double lbToKg(double lb) => lb / _lbPerKg;

/// Display a canonical-kg weight in the user's [unit].
double displayWeight(double kg, Unit unit) => unit == Unit.kg ? kg : kgToLb(kg);

/// Formats a display-unit weight: whole values show no decimal, otherwise one.
String formatWeight(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

/// A canonical-kg weight formatted for display in the user's [unit], e.g.
/// "60 kg" or "132.5 lb".
String weightLabel(double kg, Unit unit) =>
    '${formatWeight(displayWeight(kg, unit))} ${unit.name}';

/// Snap a weight (already expressed in [unit]) to the smallest loadable
/// increment — one plate pair: 2.5 kg or 5 lb.
double roundToLoadable(double value, Unit unit) {
  if (unit == Unit.kg) return roundToLoadableKg(value);
  const step = 5.0;
  return (value / step).round() * step;
}
