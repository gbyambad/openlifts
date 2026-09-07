import 'dart:math' as math;

import 'package:openlifts/core/units/loadable.dart';

/// One computed warmup set.
class WarmupSet {
  const WarmupSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;
}

/// The largest weight added between two consecutive sets of the ramp,
/// matching StrongLifts' "no jump larger than 20 kg / 45 lb" rule.
const _maxJumpKg = 20.0;

/// The heaviest first set of a loaded ramp. Deadlift/row start off the floor,
/// so they never warm up at the empty bar — but the first set scales with the
/// work weight instead of sitting at a flat 60 kg, which used to be 92% of a
/// 65 kg deadlift (and skipped warmups entirely below 60 kg).
const _maxLoadedStartKg = 60.0;

/// Computes the warmup ramp for a work set, from the anchor weight.
///
/// Empty-bar lifts start with two sets at the bar; lifts that start loaded
/// (deadlift/row — the bar rests on the floor) start at half the work weight,
/// capped at [_maxLoadedStartKg] and floored at the bar plus one plate pair so
/// there is always enough plate to lift from.
///
/// The gap from there to the work set is split into equal jumps, as few as
/// possible while keeping every jump — including the last one, into the work
/// set — at or below [_maxJumpKg]. At 100 kg that reproduces StrongLifts'
/// 20/20/40/60/80 exactly; at weights that don't divide evenly by 20 the
/// remainder is spread across the whole ramp, so the top warmup sits a full
/// jump below the work set instead of crowding it (65 kg used to warm up at
/// 60 kg — 92% — and 110 kg at 100 kg).
/// Warmups are 5 reps, except the last heavy set — StrongLifts tapers it to 3
/// to save energy for the work sets.
List<WarmupSet> computeWarmups(
  double workWeightKg, {
  required bool startsLoaded,
  double barKg = 20,
}) {
  final start = startsLoaded
      ? math.min(
          _maxLoadedStartKg,
          math.max(
            barKg + kgPlateStep * 2,
            roundToLoadableKg(workWeightKg / 2),
          ),
        )
      : barKg;
  if (workWeightKg <= start) return const [];

  final sets = <WarmupSet>[
    WarmupSet(weightKg: start, reps: 5),
    if (!startsLoaded) WarmupSet(weightKg: start, reps: 5),
  ];

  // One jump lands on the work set itself, so n ramp sets means n + 1 jumps.
  final gap = workWeightKg - start;
  final jumps = math.max(1, (gap / _maxJumpKg).ceil());
  final jump = gap / jumps;
  for (var i = 1; i < jumps; i++) {
    final loadable = roundToLoadableKg(start + jump * i);
    if (loadable <= sets.last.weightKg || loadable >= workWeightKg) continue;
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
