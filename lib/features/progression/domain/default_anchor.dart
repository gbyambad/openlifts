/// The starting working weight (kg) for a lift with no recorded progress yet:
/// exercises that begin loaded off the floor (deadlift, row) start at 40 kg,
/// everything else at an empty 20 kg bar. Returns [workingWeightKg] unchanged
/// when progress exists.
double defaultAnchorKg({
  required double? workingWeightKg,
  required bool startsLoaded,
}) =>
    workingWeightKg ?? (startsLoaded ? 40.0 : 20.0);
