/// The smallest change you can make to a barbell in kilograms: one pair of
/// 2.5 kg plates. Kept here, dependency-free, so the pure domain layer can
/// round loads without importing the Drift-backed `Unit` type in `units.dart`.
const kgPlateStep = 2.5;

/// Rounds a kilogram weight to the nearest loadable increment ([kgPlateStep]).
double roundToLoadableKg(double kg) => (kg / kgPlateStep).round() * kgPlateStep;
