import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';

/// The set schemes OpenLifts supports editing (a subset of StrongLifts' list —
/// pyramid/reverse/custom aren't modelled yet).
enum SetSchemeType { straight, topBackoff, ramp }

extension SetSchemeTypeLabel on SetSchemeType {
  String get label => switch (this) {
        SetSchemeType.straight => 'Straight sets',
        SetSchemeType.topBackoff => 'Top / Back-off',
        SetSchemeType.ramp => 'Ramp',
      };
}

/// Builds the set-groups for a chosen scheme.
List<NewSetGroup> buildSetGroups(
  SetSchemeType type,
  int sets,
  int reps, {
  double backoffPercent = 10,
}) {
  switch (type) {
    case SetSchemeType.straight:
      return [
        NewSetGroup(
          orderIndex: 0,
          sets: sets,
          reps: reps,
          weightRule: WeightRule.straight,
        ),
      ];
    case SetSchemeType.topBackoff:
      return [
        NewSetGroup(
          orderIndex: 0,
          sets: 1,
          reps: reps,
          weightRule: WeightRule.topSet,
        ),
        if (sets > 1)
          NewSetGroup(
            orderIndex: 1,
            sets: sets - 1,
            reps: reps,
            weightRule: WeightRule.backoff,
            weightParam: backoffPercent,
          ),
      ];
    case SetSchemeType.ramp:
      return [
        NewSetGroup(
          orderIndex: 0,
          sets: sets,
          reps: reps,
          weightRule: WeightRule.ramp,
        ),
      ];
  }
}

/// Derives the scheme type + total sets + reps from existing set-groups, for
/// pre-filling the editor.
({SetSchemeType type, int sets, int reps}) schemeFromGroups(
  List<SetGroup> groups,
) {
  if (groups.isEmpty) return (type: SetSchemeType.straight, sets: 5, reps: 5);
  final total = groups.fold<int>(0, (s, g) => s + g.sets);
  final reps = groups.first.reps;
  final rules = groups.map((g) => g.weightRule).toSet();
  if (rules.contains(WeightRule.ramp)) {
    return (type: SetSchemeType.ramp, sets: total, reps: reps);
  }
  if (rules.contains(WeightRule.topSet) || rules.contains(WeightRule.backoff)) {
    return (type: SetSchemeType.topBackoff, sets: total, reps: reps);
  }
  return (type: SetSchemeType.straight, sets: total, reps: reps);
}
