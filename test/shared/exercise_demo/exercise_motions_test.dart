import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/shared/exercise_demo/exercise_motions.dart';
import 'package:openlifts/shared/exercise_demo/lifter_rig.dart';

/// Every pose across one loop, finely sampled, with the pose it came from.
Iterable<(LifterPose, LifterRig)> _loop(ExerciseMotion motion) =>
    List.generate(200, (i) => (motion.poseAt(i / 200), motion.rigAt(i / 200)));

void main() {
  test('every exercise in the seeded catalog has a demo', () {
    final catalog = jsonDecode(
      File('assets/seed/exercises.json').readAsStringSync(),
    ) as List<dynamic>;

    for (final exercise in catalog.cast<Map<String, dynamic>>()) {
      final id = exercise['id'] as String;
      expect(exerciseMotionFor(id), isNotNull, reason: id);
    }
  });

  test('an unknown lift has no demo', () {
    expect(exerciseMotionFor('not_a_lift'), isNull);
  });

  for (final id in exerciseMotionIds) {
    group(id, () {
      final motion = exerciseMotionFor(id)!;

      test('hands reach their grips and feet reach the floor', () {
        for (final (pose, rig) in _loop(motion)) {
          expect((rig.hand - rig.bar).distance, lessThan(0.5));
          expect(
            (rig.ankle - (pose.ankle ?? motion.ankle)).distance,
            lessThan(0.5),
          );
          if (motion.farHand case final grip?) {
            expect((rig.farHand - grip).distance, lessThan(0.5));
          }
          if (motion.farAnkle case final foot?) {
            expect((rig.farAnkle - foot).distance, lessThan(0.5));
          }
        }
      });

      test('the plates never sink into the floor', () {
        if (motion.implement != Implement.barbell) return;
        for (final (_, rig) in _loop(motion)) {
          expect(
            rig.bar.dy,
            greaterThanOrEqualTo(motion.plateRadius - 1e-9),
          );
        }
      });

      test('strains through part of the rep, not all of it', () {
        final rigs = _loop(motion).map((e) => e.$2).toList();

        expect(rigs.any((r) => r.straining), isTrue);
        expect(rigs.any((r) => !r.straining), isTrue);
      });
    });
  }

  test('squats and deadlifts keep the bar over mid-foot', () {
    const midFoot = 100 + LifterBody.midFoot;
    for (final id in [
      'squat',
      'pause_squat',
      'front_squat',
      'deadlift',
      'pause_deadlift',
      'romanian_deadlift',
      'sumo_deadlift',
    ]) {
      for (final (_, rig) in _loop(exerciseMotionFor(id)!)) {
        expect(rig.bar.dx, closeTo(midFoot, 1.5), reason: id);
      }
    }
  });

  test('the squat reaches depth: hip crease below the knee', () {
    final bottom = _loop(exerciseMotionFor('squat')!)
        .map((e) => e.$2)
        .reduce((a, b) => a.hip.dy <= b.hip.dy ? a : b);

    expect(bottom.hip.dy, lessThan(bottom.knee.dy));
  });
}
