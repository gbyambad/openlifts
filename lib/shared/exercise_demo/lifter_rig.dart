import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Segment lengths of the cartoon lifter, in world units (y up, ground at 0).
/// Chibi proportions: a big head on a short, chunky body.
abstract final class LifterBody {
  static const headRadius = 18.0;
  static const torso = 44.0;
  static const upperArm = 25.0;
  static const forearm = 23.0;
  static const thigh = 32.0;
  static const shin = 32.0;
  static const ankleHeight = 5.0;

  /// Ankle to the mid-foot point the bar should travel over.
  static const midFoot = 6.0;

  /// A full-size plate; a bar resting on the floor sits at this height.
  static const plateRadius = 20.0;

  /// Half the shoulder width, for the front view.
  static const shoulderHalfWidth = 15.0;

  /// Half the hip width, for the front view.
  static const hipHalfWidth = 7.0;
}

/// How the hands relate to the body, which decides what a keyframe's pose
/// pins down.
enum BarHold {
  /// [LifterPose.lean] and [LifterPose.bar] are both given; elbows bend to fit.
  hands,

  /// Locked elbows: the torso angle is solved so straight arms reach the bar,
  /// and [LifterPose.lean] is ignored.
  straightArms,

  /// The hands ride the torso at [ExerciseMotion.torsoGrip] (a bar racked on
  /// the back, arms crossed on the chest), so [LifterPose.bar] is ignored.
  torso,
}

/// What the lifter holds. Drawn at the hands.
enum Implement { none, barbell, dumbbells, hammerDumbbells, cableHandle }

/// The fixture the lift happens on or in. Placed relative to the first
/// keyframe's pose, except [bench], which uses [ExerciseMotion.bench].
enum DemoProp {
  none,
  bench,
  inclineBench,
  uprightBench,
  mat,
  dipBars,
  pullUpBar,
  cableTower,
  latPulldown,
  cableRow,
  leverRow,
  legPress,
  calfMachine,
}

/// Which way the camera looks at the lifter.
enum DemoView {
  /// From the lifter's right, facing +x — shows bar paths and joint angles.
  side,

  /// Face on, mirrored left/right — for movements out to the sides.
  front,
}

/// A flat bench's pad, in world units.
class Bench {
  const Bench({required this.left, required this.right, required this.top});

  final double left;
  final double right;
  final double top;
}

/// One authored body position: where the hips and bar are, and how far the
/// torso tips forward from vertical ([lean], radians; -π/2 lies on the back,
/// +π/2 lies face down). [ankle] and [footAngle], when set, override the
/// motion's planted feet — for lifts where the feet move.
class LifterPose {
  const LifterPose({
    required this.hip,
    this.bar = Offset.zero,
    this.lean = 0,
    this.ankle,
    this.footAngle,
  });

  factory LifterPose.lerp(LifterPose a, LifterPose b, double t) => LifterPose(
        hip: Offset.lerp(a.hip, b.hip, t)!,
        bar: Offset.lerp(a.bar, b.bar, t)!,
        lean: _lerp(a.lean, b.lean, t),
        ankle: a.ankle == null || b.ankle == null
            ? a.ankle ?? b.ankle
            : Offset.lerp(a.ankle, b.ankle, t),
        footAngle: a.footAngle == null || b.footAngle == null
            ? a.footAngle ?? b.footAngle
            : _lerp(a.footAngle!, b.footAngle!, t),
      );

  final Offset hip;
  final Offset bar;
  final double lean;
  final Offset? ankle;
  final double? footAngle;
}

class MotionKeyframe {
  const MotionKeyframe(
    this.t,
    this.pose, {
    this.via = false,
    this.effort = false,
  });

  /// Position in the loop, 0–1.
  final double t;
  final LifterPose pose;

  /// The motion flows through this pose instead of stopping on it.
  final bool via;

  /// Getting here is the hard part of the rep (the concentric), so the lifter
  /// strains on the way.
  final bool effort;
}

/// A looping lift demonstration: keyframed poses plus the fixed setup (feet,
/// props, grip) needed to turn a pose into joint positions.
class ExerciseMotion {
  ExerciseMotion({
    required this.keyframes,
    required this.hold,
    this.view = DemoView.side,
    this.implement = Implement.barbell,
    this.plateRadius = LifterBody.plateRadius,
    this.prop = DemoProp.none,
    this.bench,
    this.cableFrom,
    this.torsoGrip = Offset.zero,
    this.ankle = const Offset(100, LifterBody.ankleHeight),
    this.footAngle = 0,
    this.farAnkle,
    this.farFootAngle,
    this.farHand,
    this.armScale = 1,
    this.forearmScale,
    this.thighScale = 1,
    this.elbowSide = -1,
    this.kneeSide = 1,
    this.farKneeSide,
    this.showPath = true,
  })  : assert(keyframes.first.t == 0, 'the loop starts at t = 0'),
        assert(keyframes.last.t == 1, 'the loop ends at t = 1'),
        assert(prop != DemoProp.bench || bench != null, 'bench needs a pad');

  final List<MotionKeyframe> keyframes;
  final BarHold hold;
  final DemoView view;
  final Implement implement;

  /// Smaller plates for the light barbell lifts (curls, skullcrushers).
  final double plateRadius;

  final DemoProp prop;
  final Bench? bench;

  /// The pulley a cable runs from to the hands.
  final Offset? cableFrom;

  /// Where the hands ride for [BarHold.torso], relative to the shoulder:
  /// `dx` out of the chest (negative is behind), `dy` along the torso.
  final Offset torsoGrip;

  /// Feet stay planted here unless a pose moves them.
  final Offset ankle;

  /// Heel-to-toe angle from horizontal, radians; positive tips the toes up.
  final double footAngle;

  /// The far leg's own planted foot (a split stance, a knee on a bench);
  /// null mirrors the near leg.
  final Offset? farAnkle;
  final double? farFootAngle;

  /// The far hand's own fixed grip (bracing on a bench); null mirrors the
  /// near hand.
  final Offset? farHand;

  /// Shortens the arms to fake the foreshortening of a wide grip seen from
  /// the side; 1 for a grip about shoulder-width.
  final double armScale;

  /// Overrides [armScale] for the forearm alone (a front rack, where the
  /// forearms point at the camera).
  final double? forearmScale;

  /// Foreshortens the thighs when the knees point out (a sumo stance).
  final double thighScale;

  /// Which side of the shoulder→bar line the elbow bends to: +1 is
  /// counter-clockwise (y up), -1 clockwise. [kneeSide] likewise for the
  /// hip→ankle line.
  final int elbowSide;
  final int kneeSide;
  final int? farKneeSide;

  /// Dots the bar's trajectory behind the lifter.
  final bool showPath;

  LifterPose poseAt(double t) {
    final (a, b, u) = _segmentAt(t);
    return LifterPose.lerp(a.pose, b.pose, _ease(u, a.via, b.via));
  }

  LifterRig rigAt(double t) {
    final (_, to, _) = _segmentAt(t);
    return LifterRig.solve(this, poseAt(t), straining: to.effort);
  }

  (MotionKeyframe, MotionKeyframe, double) _segmentAt(double t) {
    final tt = t - t.floorToDouble();
    var i = 0;
    while (i < keyframes.length - 2 && keyframes[i + 1].t <= tt) {
      i++;
    }
    final a = keyframes[i];
    final b = keyframes[i + 1];
    final span = b.t - a.t;
    return (a, b, span <= 0 ? 1.0 : ((tt - a.t) / span).clamp(0.0, 1.0));
  }
}

/// Smoothstep that only eases at ends where the motion actually stops, so a
/// via keyframe is passed through without a hitch.
double _ease(double u, bool fromVia, bool toVia) {
  if (fromVia && toVia) return u;
  if (fromVia) return 1 - (1 - u) * (1 - u);
  if (toVia) return u * u;
  return u * u * (3 - 2 * u);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Joint positions for one frame, in world units (y up, ground at 0). In the
/// front view the near limbs are the lifter's right side, and [hip] is the
/// pelvis center.
class LifterRig {
  const LifterRig({
    required this.hip,
    required this.knee,
    required this.ankle,
    required this.footAngle,
    required this.farKnee,
    required this.farAnkle,
    required this.farFootAngle,
    required this.shoulder,
    required this.elbow,
    required this.hand,
    required this.farElbow,
    required this.farHand,
    required this.bar,
    required this.lean,
    this.straining = false,
  });

  factory LifterRig.solve(
    ExerciseMotion motion,
    LifterPose pose, {
    bool straining = false,
  }) {
    final upperArm = LifterBody.upperArm * motion.armScale;
    final forearm =
        LifterBody.forearm * (motion.forearmScale ?? motion.armScale);
    final thigh = LifterBody.thigh * motion.thighScale;
    final hip = pose.hip;

    late final Offset shoulder;
    late final Offset bar;
    late final double lean;
    if (motion.view == DemoView.front) {
      lean = 0;
      shoulder = hip +
          const Offset(LifterBody.shoulderHalfWidth, LifterBody.torso - 4);
      bar = pose.bar;
    } else {
      switch (motion.hold) {
        case BarHold.hands:
          lean = pose.lean;
          shoulder = hip + _up(lean) * LifterBody.torso;
          bar = pose.bar;
        case BarHold.straightArms:
          bar = pose.bar;
          // Hip→shoulder→hand is itself a two-bone chain when elbows lock.
          shoulder = solveTwoBone(
            root: hip,
            target: bar,
            upper: LifterBody.torso,
            lower: upperArm + forearm,
            side: 1,
          );
          final torso = shoulder - hip;
          lean = math.atan2(torso.dx, torso.dy);
        case BarHold.torso:
          lean = pose.lean;
          shoulder = hip + _up(lean) * LifterBody.torso;
          bar = shoulder +
              _front(lean) * motion.torsoGrip.dx +
              _up(lean) * motion.torsoGrip.dy;
      }
    }

    final legRoot = motion.view == DemoView.front
        ? hip + const Offset(LifterBody.hipHalfWidth, 0)
        : hip;
    Offset leg(Offset ankle, int side) => solveTwoBone(
          root: legRoot,
          target: ankle,
          upper: thigh,
          lower: LifterBody.shin,
          side: side,
        );
    Offset arm(Offset target) => solveTwoBone(
          root: shoulder,
          target: target,
          upper: upperArm,
          lower: forearm,
          side: motion.elbowSide,
        );

    final ankleTarget = pose.ankle ?? motion.ankle;
    final knee = leg(ankleTarget, motion.kneeSide);
    final farAnkleTarget = motion.farAnkle ?? ankleTarget;
    final farKnee = motion.farAnkle == null
        ? knee
        : leg(farAnkleTarget, motion.farKneeSide ?? motion.kneeSide);
    final elbow = arm(bar);
    final farHandTarget = motion.farHand ?? bar;
    final farElbow = motion.farHand == null ? elbow : arm(farHandTarget);
    final footAngle = pose.footAngle ?? motion.footAngle;

    return LifterRig(
      hip: hip,
      knee: knee,
      ankle: _reach(knee, ankleTarget, LifterBody.shin),
      footAngle: footAngle,
      farKnee: farKnee,
      farAnkle: _reach(farKnee, farAnkleTarget, LifterBody.shin),
      farFootAngle: motion.farFootAngle ?? footAngle,
      shoulder: shoulder,
      elbow: elbow,
      hand: _reach(elbow, bar, forearm),
      farElbow: farElbow,
      farHand: _reach(farElbow, farHandTarget, forearm),
      bar: bar,
      lean: lean,
      straining: straining,
    );
  }

  final Offset hip;
  final Offset knee;
  final Offset ankle;
  final double footAngle;
  final Offset farKnee;
  final Offset farAnkle;
  final double farFootAngle;
  final Offset shoulder;
  final Offset elbow;
  final Offset hand;
  final Offset farElbow;
  final Offset farHand;
  final Offset bar;

  /// Torso angle from vertical, radians; positive tips forward.
  final double lean;

  /// On the hard part of the rep — drives the effort face.
  final bool straining;

  /// Unit vector from hip toward shoulder.
  Offset get up => _up(lean);

  /// Unit vector out of the chest.
  Offset get front => _front(lean);

  /// The head tilts less than the torso, so a lifter lying flat or hinged
  /// over still looks along the lift rather than at the floor.
  double get headTilt => lean * 0.8;

  Offset get headCenter =>
      shoulder + _up(headTilt) * (LifterBody.headRadius + 3);
}

Offset _up(double lean) => Offset(math.sin(lean), math.cos(lean));
Offset _front(double lean) => Offset(math.cos(lean), -math.sin(lean));

/// The point [length] from [from] toward [to] — where a bone of that length
/// ends when the target is out of reach.
Offset _reach(Offset from, Offset to, double length) {
  final d = to - from;
  final dist = d.distance;
  return dist == 0 ? from : from + d * (length / dist);
}

/// Places the middle joint (knee, elbow) of a two-bone chain from [root]
/// toward [target]. [side] picks the bend: +1 counter-clockwise of the
/// root→target line (y up), -1 clockwise. An unreachable target straightens
/// the chain toward it; one too close folds it as far as the bones allow.
Offset solveTwoBone({
  required Offset root,
  required Offset target,
  required double upper,
  required double lower,
  required int side,
}) {
  final delta = target - root;
  final rawDist = delta.distance;
  final dir = rawDist == 0 ? const Offset(0, -1) : delta / rawDist;
  final dist =
      rawDist.clamp(math.max((upper - lower).abs(), 1e-6), upper + lower);
  final along = (upper * upper - lower * lower + dist * dist) / (2 * dist);
  final h = math.sqrt(math.max(0, upper * upper - along * along));
  final perp = side > 0 ? Offset(-dir.dy, dir.dx) : Offset(dir.dy, -dir.dx);
  return root + dir * along + perp * h;
}
