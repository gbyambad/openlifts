import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/loadable.dart';

/// A prescribed block of sets, decoupled from the Drift row so the resolver
/// stays pure and testable.
class SetGroupSpec {
  const SetGroupSpec({
    required this.sets,
    required this.reps,
    required this.weightRule,
    this.weightParam,
  });

  final int sets;
  final int reps;
  final WeightRule weightRule;
  final double? weightParam;
}

/// One resolved set with a concrete weight.
class ResolvedSet {
  const ResolvedSet({required this.weightKg, required this.reps});

  final double weightKg;
  final int reps;
}

/// Resolves a set-group's per-set weights from the lift's [anchorKg], per the
/// group's [WeightRule]. Pure and deterministic.
List<ResolvedSet> resolveSetGroup(double anchorKg, SetGroupSpec group) {
  final weights = <double>[];
  switch (group.weightRule) {
    case WeightRule.straight:
    case WeightRule.topSet:
      for (var i = 0; i < group.sets; i++) {
        weights.add(roundToLoadableKg(anchorKg));
      }
    case WeightRule.backoff:
      final w =
          roundToLoadableKg(anchorKg * (1 - (group.weightParam ?? 0) / 100));
      for (var i = 0; i < group.sets; i++) {
        weights.add(w);
      }
    case WeightRule.percentOfAnchor:
      final w = roundToLoadableKg(anchorKg * (group.weightParam ?? 100) / 100);
      for (var i = 0; i < group.sets; i++) {
        weights.add(w);
      }
    case WeightRule.ramp:
      for (var i = 0; i < group.sets; i++) {
        final frac = group.sets == 1 ? 1.0 : 0.5 + 0.5 * (i / (group.sets - 1));
        weights.add(roundToLoadableKg(anchorKg * frac));
      }
  }
  return weights
      .map((w) => ResolvedSet(weightKg: w, reps: group.reps))
      .toList();
}
