import 'package:openlifts/core/units/loadable.dart';

/// One computed warmup set.
class WarmupSet {
  const WarmupSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;
}

/// Computes the warmup ramp for a work set, from the anchor weight.
///
/// Empty-bar lifts start with two sets at the bar; lifts that start loaded
/// (deadlift/row — the bar rests on the floor) start heavier. Intermediate
/// sets ramp up in jumps no larger than 20 kg and stay below the work weight.
/// Warmups are always 5 reps.
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

  final gap = workWeightKg - start;
  if (gap <= 20) return sets;

  final steps = (gap / 20).ceil();
  final increment = gap / steps;
  for (var i = 1; i < steps; i++) {
    final w = roundToLoadableKg(start + increment * i);
    if (w >= workWeightKg) break;
    sets.add(WarmupSet(weightKg: w, reps: 5));
  }
  return sets;
}
