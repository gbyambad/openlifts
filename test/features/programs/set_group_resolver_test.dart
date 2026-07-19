import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';

void main() {
  test('straight puts every set at the anchor', () {
    final r = resolveSetGroup(
      100,
      const SetGroupSpec(sets: 5, reps: 5, weightRule: WeightRule.straight),
    );
    expect(r.length, 5);
    expect(r.every((s) => s.weightKg == 100), isTrue);
  });

  test('ramp ascends to the anchor as the top set', () {
    final r = resolveSetGroup(
      100,
      const SetGroupSpec(sets: 5, reps: 5, weightRule: WeightRule.ramp),
    );
    expect(r.first.weightKg, 50);
    expect(r.last.weightKg, 100);
    for (var i = 1; i < r.length; i++) {
      expect(r[i].weightKg, greaterThanOrEqualTo(r[i - 1].weightKg));
    }
  });

  test('topSet is a single set at the anchor', () {
    final r = resolveSetGroup(
      100,
      const SetGroupSpec(sets: 1, reps: 3, weightRule: WeightRule.topSet),
    );
    expect(r.single.weightKg, 100);
    expect(r.single.reps, 3);
  });

  test('backoff drops by the given percent', () {
    final r = resolveSetGroup(
      100,
      const SetGroupSpec(
        sets: 1,
        reps: 8,
        weightRule: WeightRule.backoff,
        weightParam: 10,
      ),
    );
    expect(r.single.weightKg, 90);
  });

  test('percentOfAnchor scales by the given percent', () {
    final r = resolveSetGroup(
      100,
      const SetGroupSpec(
        sets: 1,
        reps: 5,
        weightRule: WeightRule.percentOfAnchor,
        weightParam: 50,
      ),
    );
    expect(r.single.weightKg, 50);
  });

  test('Top / Back-off scheme is "heavy first, then ~10% lighter"', () {
    // The StrongLifts-style program: 5 sets = 1 top set + 4 back-off sets.
    // At a 67.5 kg working weight this reproduces 67.5, then 60 ×4 exactly.
    final groups = buildSetGroups(SetSchemeType.topBackoff, 5, 5);
    final resolved = [
      for (final g in groups)
        ...resolveSetGroup(
          67.5,
          SetGroupSpec(
            sets: g.sets,
            reps: g.reps,
            weightRule: g.weightRule,
            weightParam: g.weightParam,
          ),
        ),
    ];
    expect(
      resolved.map((s) => s.weightKg).toList(),
      [67.5, 60, 60, 60, 60],
    );
  });

  test('Madcow Friday combo resolves each group correctly', () {
    const anchor = 100.0;
    final ramp = resolveSetGroup(
      anchor,
      const SetGroupSpec(sets: 4, reps: 5, weightRule: WeightRule.ramp),
    );
    final top = resolveSetGroup(
      anchor,
      const SetGroupSpec(sets: 1, reps: 3, weightRule: WeightRule.topSet),
    );
    final backoff = resolveSetGroup(
      anchor,
      const SetGroupSpec(
        sets: 1,
        reps: 8,
        weightRule: WeightRule.backoff,
        weightParam: 10,
      ),
    );
    expect(ramp.last.weightKg, 100);
    expect(top.single.weightKg, 100);
    expect(backoff.single.weightKg, 90);
  });
}
