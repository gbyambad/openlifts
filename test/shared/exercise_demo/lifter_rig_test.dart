import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/shared/exercise_demo/lifter_rig.dart';

void main() {
  group('solveTwoBone', () {
    test('keeps both bone lengths for a reachable target', () {
      const root = Offset.zero;
      const target = Offset(30, -40);

      final joint = solveTwoBone(
        root: root,
        target: target,
        upper: 32,
        lower: 32,
        side: 1,
      );

      expect((joint - root).distance, closeTo(32, 1e-9));
      expect((target - joint).distance, closeTo(32, 1e-9));
    });

    test('side picks which way the joint bends', () {
      // Straight down: counter-clockwise of "down" is +x, clockwise is -x.
      Offset solve(int side) => solveTwoBone(
            root: Offset.zero,
            target: const Offset(0, -40),
            upper: 32,
            lower: 32,
            side: side,
          );

      expect(solve(1).dx, greaterThan(0));
      expect(solve(-1).dx, lessThan(0));
    });

    test('straightens toward a target out of reach', () {
      final joint = solveTwoBone(
        root: Offset.zero,
        target: const Offset(100, 0),
        upper: 30,
        lower: 20,
        side: 1,
      );

      expect(joint.dx, closeTo(30, 1e-9));
      expect(joint.dy, closeTo(0, 1e-9));
    });
  });

  group('ExerciseMotion.poseAt', () {
    final motion = ExerciseMotion(
      hold: BarHold.hands,
      keyframes: const [
        MotionKeyframe(0, LifterPose(hip: Offset(0, 60), bar: Offset(0, 100))),
        MotionKeyframe(0.5, LifterPose(hip: Offset(0, 30), bar: Offset(0, 80))),
        MotionKeyframe(1, LifterPose(hip: Offset(0, 60), bar: Offset(0, 100))),
      ],
    );

    test('lands exactly on each keyframe', () {
      expect(motion.poseAt(0).hip, const Offset(0, 60));
      expect(motion.poseAt(0.5).hip, const Offset(0, 30));
    });

    test('eases between keyframes', () {
      final quarter = motion.poseAt(0.25).hip.dy;

      expect(quarter, closeTo(45, 1e-9)); // smoothstep midpoint is symmetric
      expect(motion.poseAt(0.05).hip.dy, greaterThan(60 - 30 * 0.1));
    });

    test('wraps past the end of the loop', () {
      expect(motion.poseAt(1.5).hip, motion.poseAt(0.5).hip);
    });
  });
}
