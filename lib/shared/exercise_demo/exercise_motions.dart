import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:openlifts/shared/exercise_demo/lifter_rig.dart';

/// The demo for [exerciseId], or null when that lift has none yet.
ExerciseMotion? exerciseMotionFor(String exerciseId) => _motions[exerciseId];

/// Every exercise id with a demo.
Iterable<String> get exerciseMotionIds => _motions.keys;

const double _midFootX = 100 + LifterBody.midFoot;
const _barOnFloor = Offset(_midFootX, LifterBody.plateRadius);
const _flatBench = Bench(left: 54, right: 140, top: 40);
const _backRack = Offset(-8, -3);

final _motions = <String, ExerciseMotion>{
  'squat': _squat,
  'pause_squat': _pauseSquat,
  'front_squat': _frontSquat,
  'lunge': _lunge,
  'good_morning': _goodMorning,
  'bench_press': _benchPress,
  'pause_bench': _pauseBench,
  'close_grip_bench': _closeGripBench,
  'bench_feet_up': _benchFeetUp,
  'incline_bench': _inclineBench,
  'db_bench': _dbBench,
  'skullcrusher': _skullcrusher,
  'barbell_row': _barbellRow,
  'db_row': _dbRow,
  'seated_cable_row': _seatedCableRow,
  'seated_lever_row': _seatedLeverRow,
  'lat_pulldown': _latPulldown,
  'overhead_press': _overheadPress,
  'push_press': _pushPress,
  'db_overhead_press_seated': _dbOverheadPressSeated,
  'deadlift': _deadlift,
  'pause_deadlift': _pauseDeadlift,
  'romanian_deadlift': _romanianDeadlift,
  'sumo_deadlift': _sumoDeadlift,
  'barbell_curl': _barbellCurl,
  'hammer_curl': _hammerCurl,
  'lateral_raise': _lateralRaise,
  'triceps_pushdown': _tricepsPushdown,
  'pallof_press': _pallofPress,
  'dips': _dips,
  'pull_up': _pullUp,
  'chin_up': _chinUp,
  'hanging_leg_raise': _hangingLegRaise,
  'situps': _situps,
  'plank': _plank,
  'leg_press': _legPress,
  'calf_raise': _calfRaise,
};

/// A rep that starts at [rest]: hold, move to [work], hold, return, hold.
/// [workIsHard] marks which leg of the trip is the concentric. The four
/// times are the turning points as fractions of the loop; a [back] of 1
/// skips the closing hold.
List<MotionKeyframe> _rep(
  LifterPose rest,
  LifterPose work, {
  required bool workIsHard,
  double leave = 0.12,
  double arrive = 0.5,
  double depart = 0.58,
  double back = 0.92,
}) =>
    [
      MotionKeyframe(0, rest),
      MotionKeyframe(leave, rest),
      MotionKeyframe(arrive, work, effort: workIsHard),
      MotionKeyframe(depart, work, effort: workIsHard),
      MotionKeyframe(back, rest, effort: !workIsHard),
      if (back < 1) MotionKeyframe(1, rest),
    ];

/// Lean for a bar gripped at [grip] (see [ExerciseMotion.torsoGrip]) that
/// keeps it over mid-foot — the balance point a good squat never leaves.
double _leanOverMidFoot(Offset hip, Offset grip) {
  final a = LifterBody.torso + grip.dy;
  final b = grip.dx;
  final r = math.sqrt(a * a + b * b);
  return math.asin((_midFootX - hip.dx) / r) - math.atan2(b, a);
}

LifterPose _rackedAt(Offset hip, Offset grip) =>
    LifterPose(hip: hip, lean: _leanOverMidFoot(hip, grip));

// ── Squats ─────────────────────────────────────────────────────────────

final LifterPose _squatTop = _rackedAt(const Offset(104, 68), _backRack);
// Hip crease below the knee: the depth StrongLifts asks for.
final LifterPose _squatBottom = _rackedAt(const Offset(84, 30), _backRack);

ExerciseMotion _backSquat(List<MotionKeyframe> keyframes) => ExerciseMotion(
      hold: BarHold.torso,
      torsoGrip: _backRack,
      armScale: 0.62,
      elbowSide: 1,
      keyframes: keyframes,
    );

final ExerciseMotion _squat = _backSquat(
  _rep(
    _squatTop,
    _squatBottom,
    workIsHard: false,
    arrive: 0.55,
    depart: 0.62,
    back: 1,
  ),
);

final ExerciseMotion _pauseSquat = _backSquat(
  _rep(
    _squatTop,
    _squatBottom,
    workIsHard: false,
    leave: 0.1,
    arrive: 0.42,
    depart: 0.68,
    back: 1,
  ),
);

// The bar sits on the front delts, so the torso stays far more upright.
const _frontRack = Offset(14, -1);

final ExerciseMotion _frontSquat = ExerciseMotion(
  hold: BarHold.torso,
  torsoGrip: _frontRack,
  forearmScale: 0.55,
  elbowSide: 1,
  keyframes: _rep(
    _rackedAt(const Offset(96, 68), _frontRack),
    _rackedAt(const Offset(84, 30), _frontRack),
    workIsHard: false,
    arrive: 0.55,
    depart: 0.62,
    back: 1,
  ),
);

final ExerciseMotion _lunge = ExerciseMotion(
  hold: BarHold.torso,
  torsoGrip: _backRack,
  armScale: 0.62,
  elbowSide: 1,
  ankle: const Offset(114, LifterBody.ankleHeight),
  farAnkle: const Offset(64, 16),
  farFootAngle: -0.9,
  keyframes: _rep(
    const LifterPose(hip: Offset(91, 63), lean: 0.05),
    // Rear knee just off the floor.
    const LifterPose(hip: Offset(90, 36), lean: 0.08),
    workIsHard: false,
    back: 0.95,
  ),
);

final ExerciseMotion _goodMorning = ExerciseMotion(
  hold: BarHold.torso,
  torsoGrip: _backRack,
  armScale: 0.62,
  elbowSide: 1,
  keyframes: _rep(
    const LifterPose(hip: Offset(101, 68), lean: 0.12),
    // Hips back, back flat, knees soft, until the torso nears parallel.
    const LifterPose(hip: Offset(82, 64), lean: 1.3),
    workIsHard: false,
    depart: 0.56,
  ),
);

// ── Bench presses ──────────────────────────────────────────────────────

const _benchHip = Offset(128, 52);
const _benchLockout =
    LifterPose(hip: _benchHip, bar: Offset(86, 95.5), lean: -math.pi / 2);
// Bar touches low on the chest, so it travels a slight J back to the shoulders.
const _benchChest =
    LifterPose(hip: _benchHip, bar: Offset(98, 66.5), lean: -math.pi / 2);

ExerciseMotion _onBench(
  List<MotionKeyframe> keyframes, {
  Implement implement = Implement.barbell,
  double plateRadius = LifterBody.plateRadius,
  double armScale = 0.92,
  Offset ankle = const Offset(152, LifterBody.ankleHeight),
  double footAngle = 0,
}) =>
    ExerciseMotion(
      hold: BarHold.hands,
      implement: implement,
      plateRadius: plateRadius,
      prop: DemoProp.bench,
      bench: _flatBench,
      ankle: ankle,
      footAngle: footAngle,
      armScale: armScale,
      keyframes: keyframes,
    );

List<MotionKeyframe> _benchRep(LifterPose lockout, LifterPose chest) => _rep(
      lockout,
      chest,
      workIsHard: false,
      depart: 0.55,
      back: 0.9,
    );

final ExerciseMotion _benchPress =
    _onBench(_benchRep(_benchLockout, _benchChest));

final ExerciseMotion _pauseBench = _onBench(
  _rep(
    _benchLockout,
    _benchChest,
    workIsHard: false,
    leave: 0.1,
    arrive: 0.4,
    depart: 0.66,
  ),
);

final ExerciseMotion _closeGripBench = _onBench(
  armScale: 1,
  _benchRep(
    const LifterPose(hip: _benchHip, bar: Offset(86, 98), lean: -math.pi / 2),
    // Elbows tucked, so the bar lands a little lower on the chest.
    const LifterPose(
      hip: _benchHip,
      bar: Offset(100, 66.5),
      lean: -math.pi / 2,
    ),
  ),
);

// Thighs up, shins level: no leg drive, no arch.
final ExerciseMotion _benchFeetUp = _onBench(
  ankle: const Offset(158, 82),
  footAngle: 1.2,
  _benchRep(_benchLockout, _benchChest),
);

final ExerciseMotion _dbBench = _onBench(
  implement: Implement.dumbbells,
  _benchRep(
    _benchLockout,
    // Dumbbells sink a little deeper than a bar can.
    const LifterPose(hip: _benchHip, bar: Offset(97, 64), lean: -math.pi / 2),
  ),
);

final ExerciseMotion _skullcrusher = _onBench(
  plateRadius: 12,
  _benchRep(
    const LifterPose(hip: _benchHip, bar: Offset(82, 95), lean: -math.pi / 2),
    // Elbows stay up; only the forearms swing the bar to the forehead.
    const LifterPose(hip: _benchHip, bar: Offset(74, 80), lean: -math.pi / 2),
  ),
);

const _inclineHip = Offset(118, 46);
const double _inclineLean = -math.pi / 3;

final ExerciseMotion _inclineBench = ExerciseMotion(
  hold: BarHold.hands,
  prop: DemoProp.inclineBench,
  ankle: const Offset(150, LifterBody.ankleHeight),
  armScale: 0.92,
  keyframes: _benchRep(
    const LifterPose(
      hip: _inclineHip,
      bar: Offset(83, 112),
      lean: _inclineLean,
    ),
    // Touches the upper chest, under the collarbones.
    const LifterPose(hip: _inclineHip, bar: Offset(93, 78), lean: _inclineLean),
  ),
);

// ── Rows and pulldowns ─────────────────────────────────────────────────

/// A pull: hold at [reach], pull hard to [pulled], pause, lower.
List<MotionKeyframe> _pullRep(LifterPose reach, LifterPose pulled) => _rep(
      reach,
      pulled,
      workIsHard: true,
      arrive: 0.42,
      depart: 0.5,
      back: 0.9,
    );

// Pendlay-style: every rep starts dead on the floor, back near horizontal.
final ExerciseMotion _barbellRow = ExerciseMotion(
  hold: BarHold.hands,
  keyframes: _rep(
    const LifterPose(hip: Offset(70, 52), bar: _barOnFloor, lean: 1.22),
    const LifterPose(hip: Offset(70, 52), bar: Offset(102, 50), lean: 1.15),
    workIsHard: true,
    leave: 0.15,
    arrive: 0.4,
    depart: 0.45,
    back: 0.85,
  ),
);

// One knee and one hand braced on the bench, the near arm rowing.
final ExerciseMotion _dbRow = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.dumbbells,
  prop: DemoProp.bench,
  bench: const Bench(left: 38, right: 134, top: 32),
  ankle: const Offset(88, LifterBody.ankleHeight),
  farAnkle: const Offset(48, 37.5),
  farFootAngle: math.pi,
  farHand: const Offset(124, 37),
  showPath: false,
  keyframes: _pullRep(
    const LifterPose(hip: Offset(80, 68), bar: Offset(123, 36), lean: 1.32),
    const LifterPose(hip: Offset(80, 68), bar: Offset(106, 66), lean: 1.32),
  ),
);

final ExerciseMotion _seatedCableRow = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.cableHandle,
  prop: DemoProp.cableRow,
  cableFrom: const Offset(168, 32),
  ankle: const Offset(124, 18),
  footAngle: math.pi / 2,
  showPath: false,
  keyframes: _pullRep(
    const LifterPose(hip: Offset(72, 22), bar: Offset(131, 56), lean: 0.35),
    // Sit tall and pull the handle into the belly, elbows behind the body.
    const LifterPose(hip: Offset(72, 22), bar: Offset(86, 46), lean: -0.12),
  ),
);

final ExerciseMotion _seatedLeverRow = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.none,
  prop: DemoProp.leverRow,
  ankle: const Offset(116, LifterBody.ankleHeight),
  keyframes: _pullRep(
    const LifterPose(hip: Offset(80, 40), bar: Offset(128, 82), lean: 0.05),
    const LifterPose(hip: Offset(80, 40), bar: Offset(88, 76), lean: 0.05),
  ),
);

final ExerciseMotion _latPulldown = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.cableHandle,
  prop: DemoProp.latPulldown,
  cableFrom: const Offset(100, 182),
  ankle: const Offset(130, LifterBody.ankleHeight),
  showPath: false,
  keyframes: _pullRep(
    const LifterPose(hip: Offset(92, 40), bar: Offset(99, 128), lean: -0.15),
    // Bar to the upper chest, leaning back a touch.
    const LifterPose(hip: Offset(92, 40), bar: Offset(103, 96), lean: -0.22),
  ),
);

// ── Presses ────────────────────────────────────────────────────────────

const _pressRack = LifterPose(
  hip: Offset(101, 68),
  bar: Offset(108, 114),
  lean: -0.03,
);
// Leaning back moves the head out of the way as the bar passes the face.
const _pressFace = LifterPose(
  hip: Offset(101, 68),
  bar: Offset(116, 134),
  lean: -0.2,
);
const _pressLockout = LifterPose(
  hip: Offset(101, 68),
  bar: Offset(104, 158),
  lean: 0.03,
);

final ExerciseMotion _overheadPress = ExerciseMotion(
  hold: BarHold.hands,
  keyframes: const [
    MotionKeyframe(0, _pressRack),
    MotionKeyframe(0.1, _pressRack),
    MotionKeyframe(0.24, _pressFace, via: true, effort: true),
    MotionKeyframe(0.42, _pressLockout, effort: true),
    MotionKeyframe(0.55, _pressLockout),
    MotionKeyframe(0.75, _pressFace, via: true),
    MotionKeyframe(0.92, _pressRack),
    MotionKeyframe(1, _pressRack),
  ],
);

// A quick knee dip, then the legs drive the bar off the shoulders.
final ExerciseMotion _pushPress = ExerciseMotion(
  hold: BarHold.hands,
  keyframes: const [
    MotionKeyframe(0, _pressRack),
    MotionKeyframe(0.08, _pressRack),
    MotionKeyframe(
      0.2,
      LifterPose(hip: Offset(99, 61), bar: Offset(106, 107)),
    ),
    MotionKeyframe(0.28, _pressFace, via: true, effort: true),
    MotionKeyframe(0.4, _pressLockout, effort: true),
    MotionKeyframe(0.55, _pressLockout),
    MotionKeyframe(0.75, _pressFace, via: true),
    MotionKeyframe(0.92, _pressRack),
    MotionKeyframe(1, _pressRack),
  ],
);

final ExerciseMotion _dbOverheadPressSeated = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.dumbbells,
  prop: DemoProp.uprightBench,
  ankle: const Offset(132, LifterBody.ankleHeight),
  keyframes: _pullRep(
    const LifterPose(hip: Offset(96, 42), bar: Offset(103, 90)),
    const LifterPose(hip: Offset(96, 42), bar: Offset(99, 130)),
  ),
);

// ── Deadlifts ──────────────────────────────────────────────────────────

const _deadliftFloor = LifterPose(hip: Offset(72, 45), bar: _barOnFloor);
const _deadliftKnee = LifterPose(
  hip: Offset(80, 58),
  bar: Offset(_midFootX, 42),
);
const _deadliftLockout = LifterPose(
  hip: Offset(101, 68),
  bar: Offset(_midFootX, 64),
);

final ExerciseMotion _deadlift = ExerciseMotion(
  hold: BarHold.straightArms,
  keyframes: const [
    MotionKeyframe(0, _deadliftFloor),
    MotionKeyframe(0.1, _deadliftFloor),
    MotionKeyframe(0.27, _deadliftKnee, via: true, effort: true),
    MotionKeyframe(0.45, _deadliftLockout, effort: true),
    MotionKeyframe(0.55, _deadliftLockout),
    MotionKeyframe(0.75, _deadliftKnee, via: true),
    MotionKeyframe(0.95, _deadliftFloor),
    MotionKeyframe(1, _deadliftFloor),
  ],
);

// Stops just off the floor, below the knee, before finishing the pull.
const _deadliftPause = LifterPose(
  hip: Offset(75, 50),
  bar: Offset(_midFootX, 32),
);

final ExerciseMotion _pauseDeadlift = ExerciseMotion(
  hold: BarHold.straightArms,
  keyframes: const [
    MotionKeyframe(0, _deadliftFloor),
    MotionKeyframe(0.08, _deadliftFloor),
    MotionKeyframe(0.2, _deadliftPause, effort: true),
    MotionKeyframe(0.38, _deadliftPause, effort: true),
    MotionKeyframe(0.5, _deadliftKnee, via: true, effort: true),
    MotionKeyframe(0.62, _deadliftLockout, effort: true),
    MotionKeyframe(0.7, _deadliftLockout),
    MotionKeyframe(0.82, _deadliftKnee, via: true),
    MotionKeyframe(0.96, _deadliftFloor),
    MotionKeyframe(1, _deadliftFloor),
  ],
);

final ExerciseMotion _romanianDeadlift = ExerciseMotion(
  hold: BarHold.straightArms,
  keyframes: _rep(
    _deadliftLockout,
    // Hips back on soft knees until the bar reaches mid-shin.
    const LifterPose(hip: Offset(76, 62), bar: Offset(_midFootX, 30)),
    workIsHard: false,
    depart: 0.56,
  ),
);

// Seen from the side, a wide stance mostly shows as lower hips and a more
// upright back; the knees point out, foreshortening the thighs.
const _sumoFloor = LifterPose(hip: Offset(90, 30), bar: _barOnFloor);
const _sumoKnee = LifterPose(hip: Offset(93, 46), bar: Offset(_midFootX, 38));
// Straight legs splayed wide stand shorter, so lockout is lower too.
const _sumoLockout =
    LifterPose(hip: Offset(100, 61), bar: Offset(_midFootX, 58));

final ExerciseMotion _sumoDeadlift = ExerciseMotion(
  hold: BarHold.straightArms,
  thighScale: 0.78,
  keyframes: const [
    MotionKeyframe(0, _sumoFloor),
    MotionKeyframe(0.1, _sumoFloor),
    MotionKeyframe(0.27, _sumoKnee, via: true, effort: true),
    MotionKeyframe(0.45, _sumoLockout, effort: true),
    MotionKeyframe(0.55, _sumoLockout),
    MotionKeyframe(0.75, _sumoKnee, via: true),
    MotionKeyframe(0.95, _sumoFloor),
    MotionKeyframe(1, _sumoFloor),
  ],
);

// ── Arms and shoulders ─────────────────────────────────────────────────

/// Up then down, the "up" leg being the hard one.
List<MotionKeyframe> _liftRep(LifterPose bottom, LifterPose top) => _rep(
      bottom,
      top,
      workIsHard: true,
      leave: 0.1,
      arrive: 0.4,
      depart: 0.48,
      back: 0.9,
    );

// Elbows pinned at the sides; only the forearms move.
const _curlTop = LifterPose(hip: Offset(100, 68), bar: Offset(113, 104));

final ExerciseMotion _barbellCurl = ExerciseMotion(
  hold: BarHold.hands,
  plateRadius: 12,
  keyframes: _liftRep(
    const LifterPose(hip: Offset(100, 68), bar: Offset(107, 67)),
    _curlTop,
  ),
);

final ExerciseMotion _hammerCurl = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.hammerDumbbells,
  keyframes: _liftRep(
    const LifterPose(hip: Offset(100, 68), bar: Offset(104, 67)),
    _curlTop,
  ),
);

// Face on: the arms rise out to the sides, elbows soft and leading.
final ExerciseMotion _lateralRaise = ExerciseMotion(
  hold: BarHold.hands,
  view: DemoView.front,
  implement: Implement.dumbbells,
  ankle: const Offset(109, LifterBody.ankleHeight),
  elbowSide: 1,
  keyframes: _liftRep(
    const LifterPose(hip: Offset(100, 68), bar: Offset(121, 66)),
    const LifterPose(hip: Offset(100, 68), bar: Offset(155, 106)),
  ),
);

final ExerciseMotion _tricepsPushdown = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.cableHandle,
  prop: DemoProp.cableTower,
  cableFrom: const Offset(144, 168),
  showPath: false,
  keyframes: _liftRep(
    const LifterPose(hip: Offset(100, 68), bar: Offset(119, 98), lean: 0.12),
    // The hard part pushes down, so "top" here is the locked-out bottom.
    const LifterPose(hip: Offset(100, 68), bar: Offset(115, 68), lean: 0.12),
  ),
);

// Press straight out and hold, resisting the cable's pull to the side.
final ExerciseMotion _pallofPress = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.cableHandle,
  prop: DemoProp.cableTower,
  cableFrom: const Offset(150, 118),
  showPath: false,
  keyframes: _rep(
    const LifterPose(hip: Offset(98, 62), bar: Offset(114, 95), lean: 0.05),
    const LifterPose(hip: Offset(98, 62), bar: Offset(146, 98), lean: 0.05),
    workIsHard: true,
    leave: 0.1,
    arrive: 0.3,
    depart: 0.62,
    back: 0.88,
  ),
);

// ── Bodyweight ─────────────────────────────────────────────────────────

const _dipGrip = Offset(100, 92);

final ExerciseMotion _dips = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.none,
  prop: DemoProp.dipBars,
  footAngle: -0.7,
  keyframes: _rep(
    const LifterPose(
      hip: Offset(91.4, 94.5),
      bar: _dipGrip,
      lean: 0.15,
      ankle: Offset(74, 38),
    ),
    // Shoulders down to elbow height, leaning forward a little.
    const LifterPose(
      hip: Offset(86.9, 71.5),
      bar: _dipGrip,
      lean: 0.4,
      ankle: Offset(70, 15),
    ),
    workIsHard: false,
    leave: 0.1,
    arrive: 0.45,
    depart: 0.5,
    back: 0.9,
  ),
);

// Out in front of the face, so the chin clears it at the top.
const _pullUpGrip = Offset(124, 160);

ExerciseMotion _hang(List<MotionKeyframe> keyframes, {double armScale = 1}) =>
    ExerciseMotion(
      hold: BarHold.hands,
      implement: Implement.none,
      prop: DemoProp.pullUpBar,
      footAngle: -0.7,
      armScale: armScale,
      keyframes: keyframes,
    );

/// A hanging pose with the shoulders at [shoulder]: hips below them along
/// [lean], feet trailing slightly behind.
LifterPose _hanging(
  Offset shoulder,
  double lean, {
  Offset grip = _pullUpGrip,
  Offset feet = const Offset(-10, -57),
  double? footAngle,
}) {
  final hip =
      shoulder - Offset(math.sin(lean), math.cos(lean)) * LifterBody.torso;
  return LifterPose(
    hip: hip,
    bar: grip,
    lean: lean,
    ankle: hip + feet,
    footAngle: footAngle,
  );
}

// A wide grip, so the arms look shorter from the side.
final ExerciseMotion _pullUp = _hang(
  armScale: 0.85,
  _liftRep(
    _hanging(const Offset(121, 120), -0.08),
    // Chin over the bar, chest toward it.
    _hanging(const Offset(106, 147), -0.2),
  ),
);

final ExerciseMotion _chinUp = _hang(
  _liftRep(
    _hanging(const Offset(122, 113), -0.05),
    _hanging(const Offset(110, 150), -0.12),
  ),
);

const _legRaiseGrip = Offset(102, 166);

final ExerciseMotion _hangingLegRaise = _hang(
  armScale: 0.9,
  _liftRep(
    _hanging(
      const Offset(99, 124),
      -0.05,
      grip: _legRaiseGrip,
      feet: const Offset(-2, -62),
      footAngle: -1,
    ),
    // Straight legs up to about horizontal.
    _hanging(
      const Offset(98, 125),
      -0.25,
      grip: _legRaiseGrip,
      feet: Offset(62 * math.sin(1.45), -62 * math.cos(1.45)),
      footAngle: 0.5,
    ),
  ),
);

final ExerciseMotion _situps = ExerciseMotion(
  hold: BarHold.torso,
  implement: Implement.none,
  prop: DemoProp.mat,
  // Arms crossed on the chest.
  torsoGrip: const Offset(12, -10),
  armScale: 0.62,
  ankle: const Offset(150, 8),
  keyframes: _liftRep(
    const LifterPose(hip: Offset(110, 16), lean: -math.pi / 2),
    const LifterPose(hip: Offset(110, 16), lean: -0.3),
  ),
);

// Forearms down, a straight line from heels to head, held while breathing.
final ExerciseMotion _plank = ExerciseMotion(
  hold: BarHold.hands,
  implement: Implement.none,
  prop: DemoProp.mat,
  ankle: const Offset(34.5, 19),
  footAngle: -math.pi / 2,
  keyframes: const [
    MotionKeyframe(
      0,
      LifterPose(hip: Offset(98, 27), bar: Offset(162, 8), lean: 1.5),
    ),
    MotionKeyframe(
      0.5,
      LifterPose(hip: Offset(98, 28), bar: Offset(162, 8), lean: 1.49),
    ),
    MotionKeyframe(
      1,
      LifterPose(hip: Offset(98, 27), bar: Offset(162, 8), lean: 1.5),
      effort: true,
    ),
  ],
);

// ── Machines ───────────────────────────────────────────────────────────

const _legPressHip = Offset(84, 30);
const _legPressLean = -0.75;

final ExerciseMotion _legPress = ExerciseMotion(
  hold: BarHold.torso,
  implement: Implement.none,
  prop: DemoProp.legPress,
  // Hands on the seat handles by the hips.
  torsoGrip: const Offset(4, -34),
  armScale: 0.9,
  footAngle: 3 * math.pi / 4,
  keyframes: _liftRep(
    const LifterPose(
      hip: _legPressHip,
      lean: _legPressLean,
      ankle: Offset(108, 52),
    ),
    // The sled rides the 45° rail out to soft, unlocked knees.
    const LifterPose(
      hip: _legPressHip,
      lean: _legPressLean,
      ankle: Offset(128, 72),
    ),
  ),
);

/// Standing with the toes fixed on the block edge and the heels at
/// [footAngle]: legs straight, so the whole body rides the ankle.
LifterPose _calfPose(double footAngle) {
  const toe = Offset(116, 13);
  final c = math.cos(footAngle);
  final s = math.sin(footAngle);
  final ankle = toe - Offset(14 * c + 0.5 * s, 14 * s - 0.5 * c);
  return LifterPose(
    hip: ankle + const Offset(1, 63.5),
    ankle: ankle,
    footAngle: footAngle,
  );
}

final ExerciseMotion _calfRaise = ExerciseMotion(
  hold: BarHold.torso,
  implement: Implement.none,
  prop: DemoProp.calfMachine,
  // Hands on the pad handles above the shoulders.
  torsoGrip: const Offset(6, 6),
  armScale: 0.7,
  keyframes: _rep(
    _calfPose(0.3),
    _calfPose(-0.5),
    workIsHard: true,
    leave: 0.1,
    arrive: 0.4,
    depart: 0.52,
    back: 0.9,
  ),
);
