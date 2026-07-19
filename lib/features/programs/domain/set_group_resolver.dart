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

/// Per-set weights for [count] working sets at [anchor], following [groups]'
/// scheme. Sets past the prescribed count track the last group's factor, so a
/// manually-added set keeps its relationship to the anchor. Unlike
/// [resolveSetGroup] this is driven by [count], so re-deriving from a new
/// working weight preserves user-added or -removed sets instead of snapping
/// back to the prescription.
List<double> resolveWeightsForCount(
  List<SetGroupSpec> groups,
  int count,
  double anchor,
) {
  final factors = anchorFactors(groups);
  final fallback = factors.isEmpty ? 1.0 : factors.last;
  return [
    for (var i = 0; i < count; i++)
      roundToLoadableKg(anchor * (i < factors.length ? factors[i] : fallback)),
  ];
}

/// The anchor multiplier for each set across [groups], in set order: the
/// factor `f` such that a set's prescribed weight is `anchor * f`.
/// straight/topSet -> 1, backoff -> `1 - p`, percentOfAnchor -> `p`, ramp -> its
/// per-position fraction. This is the inverse view of [resolveSetGroup]: it
/// lets one edited set imply an anchor (`weight / f`) the scheme re-derives from.
List<double> anchorFactors(List<SetGroupSpec> groups) {
  final factors = <double>[];
  for (final g in groups) {
    switch (g.weightRule) {
      case WeightRule.straight:
      case WeightRule.topSet:
        for (var i = 0; i < g.sets; i++) {
          factors.add(1);
        }
      case WeightRule.backoff:
        final f = 1 - (g.weightParam ?? 0) / 100;
        for (var i = 0; i < g.sets; i++) {
          factors.add(f);
        }
      case WeightRule.percentOfAnchor:
        final f = (g.weightParam ?? 100) / 100;
        for (var i = 0; i < g.sets; i++) {
          factors.add(f);
        }
      case WeightRule.ramp:
        for (var i = 0; i < g.sets; i++) {
          factors.add(g.sets == 1 ? 1.0 : 0.5 + 0.5 * (i / (g.sets - 1)));
        }
    }
  }
  return factors;
}

/// Recalculates the working-set weights when set [editedIndex] changes to
/// [editedWeight]: earlier sets unchanged; later sets re-derived from the
/// anchor the edit implies (`weight / factor`) times each set's own factor.
///
/// One rule for every scheme (like StrongLifts): straight and same-group
/// back-off edits carry the weight forward; a top-set or ramp edit re-derives
/// the later sets proportionally. Manually-added extra sets carry it forward.
List<double> recalcFromEditedSet({
  required List<SetGroupSpec> groups,
  required List<double> currentWeights,
  required int editedIndex,
  required double editedWeight,
}) {
  final w = editedWeight < 0 ? 0.0 : editedWeight;
  final factors = anchorFactors(groups);
  final editedFactor = (editedIndex >= 0 && editedIndex < factors.length)
      ? factors[editedIndex]
      : 1.0;
  // A zero factor (e.g. a 100% back-off) can't imply an anchor; fall back to
  // carrying the weight forward.
  final anchor = editedFactor == 0 ? w : w / editedFactor;
  return [
    for (var i = 0; i < currentWeights.length; i++)
      if (i < editedIndex)
        currentWeights[i]
      else if (i == editedIndex)
        w
      else if (i < factors.length)
        roundToLoadableKg(anchor * factors[i])
      else
        w,
  ];
}
