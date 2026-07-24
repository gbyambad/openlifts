import 'package:openlifts/core/units/loadable.dart';

/// One computed warmup set.
class WarmupSet {
  const WarmupSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;
}

/// The weight added between warmup sets — one plate pair, matching
/// StrongLifts' "no jump larger than 20 kg / 45 lb" rule.
const _warmupStepKg = 20.0;

/// Computes the warmup ramp for a work set, from the anchor weight.
///
/// Empty-bar lifts start with two sets at the bar; lifts that start loaded
/// (deadlift/row — the bar rests on the floor) start heavier. Intermediate
/// sets add a fixed [_warmupStepKg] each and stay below the work weight, so
/// they land on clean plate-friendly loads (40, 60, 80…) the way StrongLifts'
/// calculator does — rather than evenly dividing the gap into off-plate
/// weights. The short final jump into the work set is expected. Warmups are 5
/// reps, except the last heavy set — StrongLifts tapers it to 3 to save energy
/// for the work sets.
List<WarmupSet> computeWarmups(
  double workWeightKg, {
  required bool startsLoaded,
  double barKg = 20,
}) {
  final start = startsLoaded ? 60.0 : barKg;
  if (workWeightKg <= start) return const [];

  final sets = <WarmupSet>[
    WarmupSet(weightKg: start, reps: 5),
    if (!startsLoaded) WarmupSet(weightKg: start, reps: 5),
  ];

  for (var w = start + _warmupStepKg; w < workWeightKg; w += _warmupStepKg) {
    final loadable = roundToLoadableKg(w);
    if (loadable >= workWeightKg) break;
    sets.add(WarmupSet(weightKg: loadable, reps: 5));
  }

  // Taper the final, heaviest set to 3 reps — but only when it's a loaded ramp
  // set, never an empty-bar set (a work weight barely above the bar warms up
  // with plain empty-bar fives).
  final last = sets.last;
  if (last.weightKg > start) {
    sets[sets.length - 1] = WarmupSet(weightKg: last.weightKg, reps: 3);
  }
  return sets;
}
