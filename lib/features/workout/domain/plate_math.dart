import 'package:openlifts/core/database/tables.dart';

/// Standard loadable plates (heaviest first), per unit.
const kgPlates = [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25];
const lbPlates = [45.0, 35.0, 25.0, 10.0, 5.0, 2.5];

/// The plates to load on each side of the bar, plus any weight that couldn't be
/// matched by the available plates (rounding leftover).
class PlateLoad {
  const PlateLoad({required this.perSide, required this.leftover});

  final List<double> perSide; // plates on one side, heaviest first
  final double leftover; // unmatched weight per side (0 when it loads cleanly)

  double get perSideTotal =>
      perSide.fold<double>(0, (sum, p) => sum + p) + leftover;
}

List<double> platesFor(Unit unit) => unit == Unit.kg ? kgPlates : lbPlates;

/// Greedily breaks the per-side load of `total` (with `bar` weight, all in the
/// same unit) into `plates`. Pure.
PlateLoad platesPerSide(
  double total,
  double bar,
  List<double> plates,
) {
  var side = (total - bar) / 2;
  if (side <= 0) return const PlateLoad(perSide: [], leftover: 0);

  final result = <double>[];
  for (final plate in plates) {
    while (side + 1e-9 >= plate) {
      result.add(plate);
      side -= plate;
    }
  }
  return PlateLoad(perSide: result, leftover: side < 1e-6 ? 0 : side);
}
