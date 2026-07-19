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

  group('recalcFromEditedSet', () {
    test('straight: edit carries forward to the later sets, earlier untouched',
        () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(sets: 3, reps: 5, weightRule: WeightRule.straight),
        ],
        currentWeights: const [60, 60, 60],
        editedIndex: 1,
        editedWeight: 65,
      );
      expect(r, [60, 65, 65]); // set 0 kept
    });

    test('back-off: editing one back-off set copies to the later back-offs',
        () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(
            sets: 3,
            reps: 5,
            weightRule: WeightRule.backoff,
            weightParam: 10,
          ),
        ],
        currentWeights: const [90, 90, 90],
        editedIndex: 0,
        editedWeight: 95,
      );
      expect(r, [95, 95, 95]);
    });

    test('top set: editing the top set recalculates the back-offs 10% under',
        () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
          SetGroupSpec(
            sets: 3,
            reps: 5,
            weightRule: WeightRule.backoff,
            weightParam: 10,
          ),
        ],
        currentWeights: const [100, 90, 90, 90],
        editedIndex: 0,
        editedWeight: 150,
      );
      // Back-offs re-derive from the new top: 150 * 0.9 = 135.
      expect(r, [150, 135, 135, 135]);
    });

    test('top set: editing a back-off leaves the top set alone', () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
          SetGroupSpec(
            sets: 3,
            reps: 5,
            weightRule: WeightRule.backoff,
            weightParam: 10,
          ),
        ],
        currentWeights: const [100, 90, 90, 90],
        editedIndex: 2, // a back-off set
        editedWeight: 85,
      );
      expect(r, [100, 90, 85, 85]); // top + earlier back-off kept
    });

    test('ramp: editing a rung recalculates the following rungs by ratio', () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(sets: 5, reps: 5, weightRule: WeightRule.ramp),
        ],
        currentWeights: const [50, 62.5, 75, 87.5, 100],
        editedIndex: 0, // 0.5 * anchor -> new anchor 120
        editedWeight: 60,
      );
      expect(r, [60, 75, 90, 105, 120]);
    });

    test('sets added beyond the prescribed groups carry the weight forward',
        () {
      final r = recalcFromEditedSet(
        groups: const [
          SetGroupSpec(sets: 2, reps: 5, weightRule: WeightRule.straight),
        ],
        currentWeights: const [60, 60, 60], // one manually-added set
        editedIndex: 0,
        editedWeight: 65,
      );
      expect(r, [65, 65, 65]);
    });
  });

  test('anchorFactors maps each set to its anchor multiplier', () {
    expect(
      anchorFactors(const [
        SetGroupSpec(sets: 1, reps: 5, weightRule: WeightRule.topSet),
        SetGroupSpec(
          sets: 2,
          reps: 5,
          weightRule: WeightRule.backoff,
          weightParam: 10,
        ),
      ]),
      [1.0, 0.9, 0.9],
    );
    expect(
      anchorFactors(const [
        SetGroupSpec(sets: 3, reps: 5, weightRule: WeightRule.ramp),
      ]),
      [0.5, 0.75, 1.0],
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
