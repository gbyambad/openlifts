import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:openlifts/shared/exercise_demo/lifter_rig.dart';

/// The cartoon's colors. Baked into the sprite sheets, so they're fixed
/// rather than themed — each one reads on both the light and dark grounds.
abstract final class LifterPalette {
  static const ink = Color(0xFF2A2420);
  static const skin = Color(0xFFF7CBA4);
  static const ear = Color(0xFFEBAE85);
  static const blush = Color(0xFFF2989A);
  static const hair = Color(0xFF4A3426);
  static const shirt = Color(0xFFFF9500); // the brand orange
  static const shorts = Color(0xFF34405A);
  static const shoe = Color(0xFFFFFFFF);
  static const sole = Color(0xFF9AA3B5);
  static const plate = Color(0xFF3F7EE0);
  static const plateLip = Color(0xFF6E9FEC);
  static const steel = Color(0xFFB4BCC6);
  static const benchPad = Color(0xFFD9534F);
  static const benchFrame = Color(0xFF6B7280);
  static const stack = Color(0xFF4B5563);
  static const cable = Color(0xFF4B5563);
  static const mat = Color(0xFF5FB8A6);
  static const sweat = Color(0xFF8FD3FF);
  static const glint = Color(0xFFFFFFFF);
  static const path = Color(0x8CFF9500);
  static const shadow = Color(0x29000000);
}

enum _Layer {
  /// Behind everything: towers, rails, the far half of a fixture.
  back,

  /// After the far limbs, before the torso: what the lifter sits or lies on.
  seat,

  /// In front of the body, behind the head and near arm: pads, the near bar.
  front,
}

/// Paints [motion] at [t] (0–1 through the loop). Drawing happens in world
/// units (y up, ground at 0); [window] is the world rect stretched over the
/// canvas, its `top` holding the lowest y.
class LifterPainter extends CustomPainter {
  LifterPainter({required this.motion, required this.t, required this.window});

  final ExerciseMotion motion;
  final double t;
  final Rect window;

  static const _outline = 2.2;
  static const _torsoWidth = 26.0;
  static const _legWidth = 11.0;
  static const _armWidth = 9.0;

  /// Far-side limbs and plate sit up and back a little, for a hint of depth.
  static const _depth = Offset(3.5, 3);

  LifterPose get _start => motion.keyframes.first.pose;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..translate(0, size.height)
      ..scale(size.width / window.width, -size.height / window.height)
      ..translate(-window.left, -window.top);

    final rig = motion.rigAt(t);
    if (motion.view == DemoView.front) {
      _paintFront(canvas, rig);
    } else {
      _paintSide(canvas, rig);
    }
    canvas.restore();
  }

  void _paintSide(Canvas canvas, LifterRig rig) {
    _shadows(canvas, rig);
    _prop(canvas, rig, _Layer.back);
    if (_showsPath) _barPath(canvas, (r) => r.bar);
    if (motion.implement == Implement.barbell) _plates(canvas, rig.bar);
    _cable(canvas, rig);

    _leg(
      canvas,
      rig.hip + _depth,
      rig.farKnee + _depth,
      rig.farAnkle + _depth,
      rig.farFootAngle,
      far: true,
    );
    // A far hand with its own grip is bracing on something, not holding.
    if (motion.farHand == null) {
      _held(canvas, rig.farHand + _depth, rig.farElbow + _depth, far: true);
    }
    _arm(
      canvas,
      rig.shoulder + _depth,
      rig.farElbow + _depth,
      rig.farHand + _depth,
      far: true,
    );

    _prop(canvas, rig, _Layer.seat);
    _torso(canvas, rig);
    _leg(canvas, rig.hip, rig.knee, rig.ankle, rig.footAngle);
    _prop(canvas, rig, _Layer.front);
    _head(canvas, rig);
    _held(canvas, rig.hand, rig.elbow);
    _arm(canvas, rig.shoulder, rig.elbow, rig.hand);
  }

  bool get _showsPath => motion.showPath && motion.implement != Implement.none;

  void _shadows(Canvas canvas, LifterRig rig) {
    if (motion.prop == DemoProp.mat) return;
    final shadow = _fill(LifterPalette.shadow);
    final hanging =
        motion.prop == DemoProp.pullUpBar || motion.prop == DemoProp.dipBars;
    // Hanging feet move around; the shadow stays under the body.
    final feet = hanging ? [rig.hip.dx - 5] : [rig.ankle.dx, rig.farAnkle.dx];
    final left = feet.reduce(math.min);
    final right = feet.reduce(math.max);
    canvas.drawOval(
      Rect.fromLTRB(left - 22, -3.5, right + 32, 3.5),
      shadow,
    );
    final bench = motion.bench;
    if (motion.prop == DemoProp.bench && bench != null) {
      canvas.drawOval(
        Rect.fromLTRB(bench.left - 2, -3.5, bench.right + 2, 3.5),
        shadow,
      );
    }
  }

  /// The implement's whole-rep trajectory, dotted — the cue to keep it on
  /// line.
  void _barPath(Canvas canvas, Offset Function(LifterRig) point) {
    final dots = _fill(LifterPalette.path);
    Offset? last;
    for (var i = 0; i < 120; i++) {
      final p = point(motion.rigAt(i / 120));
      if (last != null && (p - last).distance < 4) continue;
      canvas.drawCircle(p, 1.1, dots);
      last = p;
    }
  }

  void _plates(Canvas canvas, Offset bar) {
    _plate(canvas, bar + _depth, motion.plateRadius, far: true);
    _inked(canvas, [bar + _depth, bar], 4, LifterPalette.steel);
    _plate(canvas, bar, motion.plateRadius);
  }

  void _plate(Canvas canvas, Offset center, double r, {bool far = false}) {
    _disc(canvas, center, r, _shade(LifterPalette.plate, far));
    canvas.drawCircle(
      center,
      r * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r / 10
        ..color = _shade(LifterPalette.plateLip, far),
    );
    _disc(canvas, center, math.min(5, r * 0.3), LifterPalette.steel);
  }

  void _cable(Canvas canvas, LifterRig rig) {
    final from = motion.cableFrom;
    if (from == null) return;
    _stroke(canvas, [from, rig.hand], 1.6, LifterPalette.cable);
    _disc(canvas, from, 4.5, LifterPalette.steel);
  }

  /// What the hand grips, drawn just before the hand closes over it.
  void _held(Canvas canvas, Offset hand, Offset elbow, {bool far = false}) {
    switch (motion.implement) {
      case Implement.none || Implement.barbell:
        return;
      case Implement.dumbbells:
        // End-on: the near head, a stub of handle, the far head behind.
        _disc(canvas, hand + _depth * 0.9, 7, _shade(LifterPalette.stack, far));
        _inked(
          canvas,
          [hand + _depth * 0.9, hand - _depth * 0.6],
          3.5,
          LifterPalette.steel,
        );
        _disc(canvas, hand - _depth * 0.6, 7, _shade(LifterPalette.plate, far));
      case Implement.hammerDumbbells:
        // Neutral grip: the handle lies across the forearm, heads either end.
        final along = _unit(hand - elbow);
        final across = Offset(-along.dy, along.dx);
        final color = _shade(LifterPalette.plate, far);
        for (final end in [hand + across * 8, hand - across * 8]) {
          _inked(canvas, [end - along * 3, end + along * 3], 7.5, color);
        }
        _inked(
          canvas,
          [hand + across * 5, hand - across * 5],
          3,
          LifterPalette.steel,
        );
      case Implement.cableHandle:
        final from = motion.cableFrom;
        final pull = from == null ? const Offset(1, 0) : _unit(from - hand);
        final across = Offset(-pull.dy, pull.dx);
        _inked(
          canvas,
          [hand + across * 5, hand - across * 5],
          3.5,
          LifterPalette.steel,
        );
    }
  }

  void _torso(Canvas canvas, LifterRig rig) {
    final hip = rig.hip;
    _inked(canvas, [hip, rig.shoulder], _torsoWidth, LifterPalette.shirt);
    // Shorts: a rounded seat with a straight waistband.
    final waist = hip + rig.up * 9;
    canvas.drawCircle(hip, _torsoWidth / 2, _fill(LifterPalette.shorts));
    _stroke(
      canvas,
      [hip, waist],
      _torsoWidth,
      LifterPalette.shorts,
      cap: StrokeCap.butt,
    );
    final across = rig.front * (_torsoWidth / 2);
    _stroke(canvas, [waist - across, waist + across], 1.4, LifterPalette.ink);
  }

  void _leg(
    Canvas canvas,
    Offset hip,
    Offset knee,
    Offset ankle,
    double footAngle, {
    bool far = false,
  }) {
    final hem = Offset.lerp(hip, knee, 0.6)!;
    _stroke(
      canvas,
      [hip, knee, ankle],
      _legWidth + _outline * 2,
      LifterPalette.ink,
    );
    _stroke(
      canvas,
      [hem, knee, ankle],
      _legWidth,
      _shade(LifterPalette.skin, far),
    );
    _stroke(
      canvas,
      [hip, hem],
      _legWidth + 2,
      _shade(LifterPalette.shorts, far),
    );

    // Shoe: heel just behind the ankle, chunky toe well in front.
    Offset foot(double x, double y) => ankle + _rotate(Offset(x, y), footAngle);
    _inked(
      canvas,
      [foot(-3, -0.5), foot(14, -0.5)],
      9,
      _shade(LifterPalette.shoe, far),
    );
    _stroke(
      canvas,
      [foot(-3, -3.5), foot(14, -3.5)],
      2.4,
      _shade(LifterPalette.sole, far),
    );
  }

  void _arm(
    Canvas canvas,
    Offset shoulder,
    Offset elbow,
    Offset hand, {
    bool far = false,
  }) {
    final cuff = Offset.lerp(shoulder, elbow, 0.45)!;
    _stroke(
      canvas,
      [shoulder, elbow, hand],
      _armWidth + _outline * 2,
      LifterPalette.ink,
    );
    _stroke(
      canvas,
      [cuff, elbow, hand],
      _armWidth,
      _shade(LifterPalette.skin, far),
    );
    _stroke(
      canvas,
      [shoulder, cuff],
      _armWidth + 1.5,
      _shade(LifterPalette.shirt, far),
    );
    _disc(canvas, hand, 5.2, _shade(LifterPalette.skin, far));
  }

  void _head(Canvas canvas, LifterRig rig) {
    const r = LifterBody.headRadius;
    // Local frame: x out of the face, y up through the crown.
    canvas
      ..save()
      ..translate(rig.headCenter.dx, rig.headCenter.dy)
      ..rotate(-rig.headTilt);
    _disc(canvas, Offset.zero, r, LifterPalette.skin);
    canvas
      ..drawPath(_hair, _fill(LifterPalette.hair))
      // A soft tone with no outline — an outlined circle here reads as an eye.
      ..drawCircle(const Offset(-3.5, -2.5), 3.6, _fill(LifterPalette.ear))
      ..drawOval(
        Rect.fromCenter(center: const Offset(9, -4.5), width: 7, height: 4),
        _fill(LifterPalette.blush.withValues(alpha: 0.75)),
      );
    if (rig.straining) {
      canvas
        ..drawPath(_squint, _line())
        ..drawCircle(const Offset(14, -8), 1.8, _fill(LifterPalette.ink));
      _sweatDrop(canvas, 1);
    } else {
      _eye(canvas, const Offset(10, 1.5));
      canvas.drawPath(_smile, _line());
    }
    canvas.restore();
  }

  void _eye(Canvas canvas, Offset center) {
    canvas
      ..drawOval(
        Rect.fromCenter(center: center, width: 4.4, height: 6.4),
        _fill(LifterPalette.ink),
      )
      ..drawCircle(
        center + const Offset(0.8, 1.4),
        1.1,
        _fill(LifterPalette.glint),
      );
  }

  /// Head-local; [side] mirrors it to the other temple for the front view.
  void _sweatDrop(Canvas canvas, double side) {
    canvas
      ..save()
      ..scale(side, 1)
      ..drawPath(_sweat, _fill(LifterPalette.sweat))
      ..drawPath(_sweat, _line()..strokeWidth = 1.2)
      ..restore();
  }

  /// Hair over the top and back of the head, sweeping into a fringe, plus a
  /// tuft on the crown. Head-local coordinates, like the face paths below.
  static final Path _hair = () {
    const r = LifterBody.headRadius - 1;
    const start = 40 * math.pi / 180;
    final fringeEnd = Offset(math.cos(start), math.sin(start)) * r;
    return Path()
      ..arcTo(
        Rect.fromCircle(center: Offset.zero, radius: r),
        start,
        195 * math.pi / 180,
        true,
      )
      ..quadraticBezierTo(-4, -2, 1, 6)
      ..quadraticBezierTo(8, 7, fringeEnd.dx, fringeEnd.dy)
      ..close()
      ..addPath(_tuft, Offset.zero);
  }();

  static final _tuft = Path()
    ..moveTo(-3, LifterBody.headRadius - 1)
    ..quadraticBezierTo(-1, 27, 6, 25)
    ..quadraticBezierTo(1, 22, 2, LifterBody.headRadius - 1)
    ..close();

  /// A ">" eye squeezed shut with effort.
  static final _squint = Path()
    ..moveTo(8, 4.5)
    ..lineTo(11.5, 1.5)
    ..lineTo(8, -1.5);

  static final _smile = Path()
    ..moveTo(12, -6.5)
    ..quadraticBezierTo(14, -9.5, 16, -6.5);

  static final _sweat = Path()
    ..moveTo(-12, 19)
    ..quadraticBezierTo(-8, 13, -12, 10.5)
    ..quadraticBezierTo(-16, 13, -12, 19)
    ..close();

  // ── Front view ────────────────────────────────────────────────────────

  /// Face on, mirrored about the pelvis: the rig's near limbs are the
  /// lifter's right side (screen right).
  void _paintFront(Canvas canvas, LifterRig rig) {
    final cx = rig.hip.dx;
    Offset mirror(Offset p) => Offset(2 * cx - p.dx, p.dy);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, 0), width: 64, height: 7),
      _fill(LifterPalette.shadow),
    );
    if (_showsPath) {
      _barPath(canvas, (r) => r.bar);
      _barPath(canvas, (r) => mirror(r.bar));
    }

    for (final side in [-1.0, 1.0]) {
      Offset m(Offset p) => side > 0 ? p : mirror(p);
      final root = m(rig.hip + const Offset(LifterBody.hipHalfWidth, 0));
      final ankle = m(rig.ankle);
      _stroke(
        canvas,
        [root, m(rig.knee), ankle],
        _legWidth + 1 + _outline * 2,
        LifterPalette.ink,
      );
      _stroke(
        canvas,
        [m(rig.knee), ankle],
        _legWidth + 1,
        LifterPalette.skin,
      );
      _stroke(
        canvas,
        [root, Offset.lerp(root, m(rig.knee), 0.6)!],
        _legWidth + 3,
        LifterPalette.shorts,
      );
      // Shoes face the camera: a rounded toe cap.
      final toe = Rect.fromCenter(
        center: Offset(ankle.dx + side * 1.5, 4.5),
        width: 13,
        height: 9,
      );
      canvas
        ..drawOval(toe.inflate(_outline), _fill(LifterPalette.ink))
        ..drawOval(toe, _fill(LifterPalette.shoe));
    }

    final hip = rig.hip;
    final neck = Offset(cx, rig.shoulder.dy - 4);
    _inked(canvas, [hip, neck], 34, LifterPalette.shirt);
    // Shorts fill the torso's rounded bottom up to a straight waistband.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTRB(cx - 17, hip.dy - 17, cx + 17, hip.dy + 9),
        bottomLeft: const Radius.circular(17),
        bottomRight: const Radius.circular(17),
      ),
      _fill(LifterPalette.shorts),
    );
    _stroke(
      canvas,
      [Offset(cx - 17, hip.dy + 9), Offset(cx + 17, hip.dy + 9)],
      1.4,
      LifterPalette.ink,
    );

    _frontHead(canvas, rig, Offset(cx, rig.shoulder.dy + 21));

    for (final side in [-1.0, 1.0]) {
      Offset m(Offset p) => side > 0 ? p : mirror(p);
      if (motion.implement == Implement.dumbbells) {
        // Palms down, the dumbbell points at the camera: one round head.
        _disc(canvas, m(rig.hand), 7, LifterPalette.plate);
      }
      _arm(canvas, m(rig.shoulder), m(rig.elbow), m(rig.hand));
    }
  }

  void _frontHead(Canvas canvas, LifterRig rig, Offset center) {
    const r = LifterBody.headRadius;
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    for (final side in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(side * 17, -2), 4, _fill(LifterPalette.ear));
    }
    _disc(canvas, Offset.zero, r, LifterPalette.skin);
    canvas.drawPath(_frontHair, _fill(LifterPalette.hair));
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(side * 10, -4.5), width: 7, height: 4),
        _fill(LifterPalette.blush.withValues(alpha: 0.75)),
      );
      if (rig.straining) {
        // Both eyes squeezed toward the nose: > <.
        canvas.drawPath(
          Path()
            ..moveTo(side * 9, 4.5)
            ..lineTo(side * 5.5, 1.5)
            ..lineTo(side * 9, -1.5),
          _line(),
        );
      } else {
        _eye(canvas, Offset(side * 6.5, 1.5));
      }
    }
    if (rig.straining) {
      canvas.drawCircle(const Offset(0, -9), 1.8, _fill(LifterPalette.ink));
      _sweatDrop(canvas, -1);
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(-2.5, -8)
          ..quadraticBezierTo(0, -10.5, 2.5, -8),
        _line(),
      );
    }
    canvas.restore();
  }

  static final _frontHair = Path()
    ..arcTo(
      Rect.fromCircle(
        center: Offset.zero,
        radius: LifterBody.headRadius - 1,
      ),
      math.pi * 0.05,
      math.pi * 0.9,
      true,
    )
    ..quadraticBezierTo(-12, 4, -6, 9)
    ..quadraticBezierTo(0, 5, 4, 10)
    ..quadraticBezierTo(10, 5, 16.9, 2.6)
    ..close()
    ..addPath(_tuft, Offset.zero);

  // ── Props ─────────────────────────────────────────────────────────────

  void _prop(Canvas canvas, LifterRig rig, _Layer layer) {
    switch ((motion.prop, layer)) {
      case (DemoProp.bench, _Layer.seat):
        _flatBench(canvas, motion.bench!);
      case (DemoProp.inclineBench, _Layer.seat):
        _inclineBench(canvas);
      case (DemoProp.uprightBench, _Layer.seat):
        _uprightBench(canvas);
      case (DemoProp.mat, _Layer.back):
        _box(
          canvas,
          const Rect.fromLTRB(22, 0, 186, 3),
          LifterPalette.mat,
          1.5,
        );
      case (DemoProp.dipBars, _Layer.back):
        _dipBar(canvas, _start.bar + _depth * 1.4, far: true);
      case (DemoProp.dipBars, _Layer.front):
        _dipBar(canvas, _start.bar);
      case (DemoProp.pullUpBar, _Layer.back):
        _pullUpFrame(canvas, _start.bar);
      case (DemoProp.pullUpBar, _Layer.front):
        _disc(canvas, _start.bar, 3.5, LifterPalette.steel);
      case (DemoProp.cableTower, _Layer.back):
        _tower(canvas, motion.cableFrom!);
      case (DemoProp.latPulldown, _Layer.back):
        _latFrame(canvas);
      case (DemoProp.latPulldown, _Layer.seat):
        _seat(canvas, _start.hip);
      case (DemoProp.latPulldown, _Layer.front):
        // Thigh roller pinning the knees down.
        final roller = rig.knee + const Offset(-6, 10);
        _inked(
          canvas,
          [roller, Offset(roller.dx, rig.hip.dy - 13)],
          3,
          LifterPalette.benchFrame,
        );
        _disc(canvas, roller, 5.5, LifterPalette.benchPad);
      case (DemoProp.cableRow, _Layer.back):
        _tower(canvas, motion.cableFrom!);
      case (DemoProp.cableRow, _Layer.seat):
        _cableRowSeat(canvas);
      case (DemoProp.leverRow, _Layer.back):
        _leverFrame(canvas);
      case (DemoProp.leverRow, _Layer.seat):
        _seat(canvas, _start.hip);
      case (DemoProp.leverRow, _Layer.front):
        _leverRowFront(canvas, rig);
      case (DemoProp.legPress, _Layer.back):
        _legPressRails(canvas);
      case (DemoProp.legPress, _Layer.seat):
        _reclinedSeat(canvas);
      case (DemoProp.legPress, _Layer.front):
        _legPressSled(canvas, rig);
      case (DemoProp.calfMachine, _Layer.back):
        _calfFrame(canvas, rig);
      case (DemoProp.calfMachine, _Layer.seat):
        final toe = rig.ankle + _rotate(const Offset(14, -0.5), rig.footAngle);
        _box(
          canvas,
          Rect.fromLTRB(toe.dx - 20, 0, toe.dx + 4, toe.dy - 4.5),
          LifterPalette.stack,
          1.5,
        );
      case (DemoProp.calfMachine, _Layer.front):
        _box(
          canvas,
          Rect.fromCenter(
            center: rig.shoulder + const Offset(-1, 12),
            width: 24,
            height: 7,
          ),
          LifterPalette.benchPad,
          3,
        );
      default:
        return;
    }
  }

  void _flatBench(Canvas canvas, Bench bench) {
    const frame = LifterPalette.benchFrame;
    final legTop = bench.top - 7;
    for (final x in [bench.left + 10, bench.right - 16]) {
      _box(canvas, Rect.fromLTRB(x, 0, x + 6, legTop), frame, 1);
      _box(canvas, Rect.fromLTRB(x - 8, 0, x + 14, 3), frame, 1.5);
    }
    _box(
      canvas,
      Rect.fromLTRB(bench.left, bench.top - 9, bench.right, bench.top),
      LifterPalette.benchPad,
      3,
    );
  }

  /// A seat pad on a post, under [hip].
  void _seat(Canvas canvas, Offset hip) {
    final top = hip.dy - 13;
    _box(
      canvas,
      Rect.fromLTRB(hip.dx - 3, 0, hip.dx + 3, top - 4),
      LifterPalette.benchFrame,
      1,
    );
    _box(
      canvas,
      Rect.fromLTRB(hip.dx - 12, 0, hip.dx + 12, 3),
      LifterPalette.benchFrame,
      1.5,
    );
    _box(
      canvas,
      Rect.fromLTRB(hip.dx - 15, top - 7, hip.dx + 15, top),
      LifterPalette.benchPad,
      3,
    );
  }

  /// A pad under the back of the start pose, from just below the hip to past
  /// the shoulders.
  void _backPad(Canvas canvas, {double from = -4, double to = 54}) {
    final lean = _start.lean;
    final up = Offset(math.sin(lean), math.cos(lean));
    final back = Offset(-math.cos(lean), math.sin(lean));
    final line = _start.hip + back * 17;
    _inked(
      canvas,
      [line + up * from, line + up * to],
      8,
      LifterPalette.benchPad,
    );
  }

  void _inclineBench(Canvas canvas) {
    final lean = _start.lean;
    final back = Offset(-math.cos(lean), math.sin(lean));
    final up = Offset(math.sin(lean), math.cos(lean));
    final strut = _start.hip + back * 20 + up * 26;
    _inked(
      canvas,
      [strut, Offset(strut.dx, 2)],
      5,
      LifterPalette.benchFrame,
    );
    _seat(canvas, _start.hip + const Offset(4, 0));
    _backPad(canvas);
  }

  void _uprightBench(Canvas canvas) {
    final hip = _start.hip;
    _seat(canvas, hip + const Offset(2, 0));
    final x = hip.dx - 20;
    _box(
      canvas,
      Rect.fromLTRB(x - 3, hip.dy - 16, x + 3, hip.dy + 4),
      LifterPalette.benchFrame,
      1,
    );
    _box(
      canvas,
      Rect.fromLTRB(x - 4, hip.dy - 6, x + 4, hip.dy + 44),
      LifterPalette.benchPad,
      3,
    );
  }

  void _reclinedSeat(Canvas canvas) {
    final lean = _start.lean;
    final front = Offset(math.cos(lean), -math.sin(lean));
    final up = Offset(math.sin(lean), math.cos(lean));
    final back = -front;
    final corner = _start.hip + back * 17 - up * 10;
    _inked(
      canvas,
      [corner + front * 2, corner + front * 30],
      8,
      LifterPalette.benchPad,
    );
    _backPad(canvas, from: -8, to: 50);
    _inked(
      canvas,
      [corner + front * 12, Offset(corner.dx + 6, 2)],
      5,
      LifterPalette.benchFrame,
    );
  }

  void _dipBar(Canvas canvas, Offset grip, {bool far = false}) {
    final frame = _shade(LifterPalette.benchFrame, far);
    final ends = [grip.dx - 44, grip.dx + 30];
    for (final x in ends) {
      _inked(canvas, [Offset(x, grip.dy), Offset(x, 1)], 4, frame);
    }
    _inked(
      canvas,
      [Offset(ends.first, grip.dy), Offset(ends.last, grip.dy)],
      4.5,
      _shade(LifterPalette.steel, far),
    );
  }

  /// A wall-mounted bar: the post behind the lifter, an arm out to the bar.
  void _pullUpFrame(Canvas canvas, Offset bar) {
    final postX = bar.dx - 38;
    _box(
      canvas,
      Rect.fromLTRB(postX - 4, 0, postX + 4, bar.dy + 16),
      LifterPalette.benchFrame,
      1.5,
    );
    _inked(
      canvas,
      [Offset(postX, bar.dy + 10), bar + const Offset(0, 3)],
      4,
      LifterPalette.benchFrame,
    );
  }

  /// A cable column just beyond [pulley], with its weight stack.
  void _tower(Canvas canvas, Offset pulley) {
    final left = pulley.dx + 3;
    final top = math.max(pulley.dy + 14, 140).toDouble();
    _box(
      canvas,
      Rect.fromLTRB(left, 0, left + 13, top),
      LifterPalette.benchFrame,
      2,
    );
    _weightStack(canvas, left + 2.5, left + 10.5);
    _inked(
      canvas,
      [pulley, Offset(left + 2, pulley.dy)],
      3,
      LifterPalette.benchFrame,
    );
  }

  void _weightStack(Canvas canvas, double left, double right) {
    for (var i = 0; i < 5; i++) {
      final y = 4 + i * 6.0;
      _box(
        canvas,
        Rect.fromLTRB(left, y, right, y + 5),
        LifterPalette.stack,
        1,
      );
    }
  }

  void _latFrame(Canvas canvas) {
    final pulley = motion.cableFrom!;
    final x = _start.hip.dx - 40;
    _box(
      canvas,
      Rect.fromLTRB(x, 0, x + 12, pulley.dy + 12),
      LifterPalette.benchFrame,
      2,
    );
    _weightStack(canvas, x + 2, x + 10);
    _box(
      canvas,
      Rect.fromLTRB(x, pulley.dy + 4, pulley.dx + 6, pulley.dy + 12),
      LifterPalette.benchFrame,
      2,
    );
  }

  void _cableRowSeat(Canvas canvas) {
    final hip = _start.hip;
    final plateX = motion.ankle.dx + 8;
    _box(
      canvas,
      Rect.fromLTRB(hip.dx - 30, 0, plateX + 6, hip.dy - 13),
      LifterPalette.benchFrame,
      2,
    );
    _box(
      canvas,
      Rect.fromLTRB(hip.dx - 26, hip.dy - 19, hip.dx + 16, hip.dy - 12),
      LifterPalette.benchPad,
      3,
    );
    // Foot plate, angled back toward the lifter.
    _inked(
      canvas,
      [Offset(plateX, hip.dy - 13), Offset(plateX - 4, motion.ankle.dy + 18)],
      5,
      LifterPalette.benchFrame,
    );
  }

  Offset get _leverPivot => Offset(_start.bar.dx + 24, 150);

  void _leverFrame(Canvas canvas) {
    final pivot = _leverPivot;
    _box(
      canvas,
      Rect.fromLTRB(pivot.dx + 2, 0, pivot.dx + 12, pivot.dy + 6),
      LifterPalette.benchFrame,
      2,
    );
    // Chest pad post, from the floor up to the pad.
    final pad = _chestPad;
    _box(
      canvas,
      Rect.fromLTRB(pad.center.dx + 1, 0, pad.center.dx + 7, pad.center.dy),
      LifterPalette.benchFrame,
      1,
    );
  }

  Rect get _chestPad {
    final lean = _start.lean;
    final shoulder =
        _start.hip + Offset(math.sin(lean), math.cos(lean)) * LifterBody.torso;
    return Rect.fromCenter(
      center: shoulder +
          Offset(math.cos(lean), -math.sin(lean)) * 18 -
          const Offset(0, 16),
      width: 8,
      height: 30,
    );
  }

  void _leverRowFront(Canvas canvas, LifterRig rig) {
    _box(canvas, _chestPad, LifterPalette.benchPad, 4);
    final pivot = _leverPivot;
    final arm = _unit(rig.bar - pivot);
    _inked(canvas, [pivot - arm * 16, rig.bar], 5, LifterPalette.steel);
    _plate(canvas, pivot - arm * 16, 10);
    _disc(canvas, pivot, 3, LifterPalette.benchFrame);
    _inked(
      canvas,
      [rig.bar - const Offset(0, 6), rig.bar + const Offset(0, 6)],
      4,
      LifterPalette.ink,
    );
  }

  /// The sled runs along the leg-press rail; its plate sits on the soles.
  Offset get _railDirection => const Offset(math.sqrt1_2, math.sqrt1_2);

  void _legPressRails(Canvas canvas) {
    final dir = _railDirection;
    final normal = Offset(dir.dy, -dir.dx);
    final start = (_start.ankle ?? motion.ankle) + normal * 16;
    _inked(
      canvas,
      [start - dir * 24, start + dir * 64],
      6,
      LifterPalette.benchFrame,
    );
    final foot = start - dir * 24;
    _inked(
      canvas,
      [foot, Offset(foot.dx, 2)],
      5,
      LifterPalette.benchFrame,
    );
    _box(
      canvas,
      Rect.fromLTRB(_start.hip.dx - 30, 0, foot.dx + 8, 4),
      LifterPalette.benchFrame,
      1.5,
    );
  }

  void _legPressSled(Canvas canvas, LifterRig rig) {
    final dir = _railDirection;
    final across = Offset(-dir.dy, dir.dx);
    final plate = rig.ankle + dir * 7;
    _inked(
      canvas,
      [plate - across * 6, plate + across * 20],
      5,
      LifterPalette.benchFrame,
    );
    _plate(canvas, plate + dir * 10 + across * 4, 11);
  }

  void _calfFrame(Canvas canvas, LifterRig rig) {
    final x = rig.hip.dx - 44;
    _box(
      canvas,
      Rect.fromLTRB(x, 0, x + 12, 172),
      LifterPalette.benchFrame,
      2,
    );
    _weightStack(canvas, x + 2, x + 10);
    final armY = rig.shoulder.dy + 12;
    _inked(
      canvas,
      [Offset(x + 6, armY), Offset(rig.shoulder.dx, armY)],
      4,
      LifterPalette.benchFrame,
    );
  }

  // ── Drawing helpers ───────────────────────────────────────────────────

  /// A filled circle with the cartoon outline.
  void _disc(Canvas canvas, Offset center, double r, Color color) {
    canvas
      ..drawCircle(center, r + _outline / 2, _fill(LifterPalette.ink))
      ..drawCircle(center, r - _outline / 2, _fill(color));
  }

  /// A rounded rectangle with the cartoon outline.
  void _box(Canvas canvas, Rect rect, Color color, double radius) {
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(_outline / 2),
          Radius.circular(radius + _outline / 2),
        ),
        _fill(LifterPalette.ink),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(_outline / 2),
          Radius.circular(radius),
        ),
        _fill(color),
      );
  }

  /// A thick rounded stroke with the cartoon outline.
  void _inked(Canvas canvas, List<Offset> points, double width, Color color) {
    _stroke(canvas, points, width + _outline * 2, LifterPalette.ink);
    _stroke(canvas, points, width, color);
  }

  void _stroke(
    Canvas canvas,
    List<Offset> points,
    double width,
    Color color, {
    StrokeCap cap = StrokeCap.round,
  }) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = cap
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  Paint _line() => Paint()
    ..color = LifterPalette.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Paint _fill(Color color) => Paint()..color = color;

  Color _shade(Color color, bool far) =>
      far ? Color.lerp(color, LifterPalette.ink, 0.22)! : color;

  @override
  bool shouldRepaint(LifterPainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.t != t ||
      oldDelegate.window != window;
}

Offset _rotate(Offset p, double angle) {
  final c = math.cos(angle);
  final s = math.sin(angle);
  return Offset(p.dx * c - p.dy * s, p.dx * s + p.dy * c);
}

Offset _unit(Offset v) => v.distance == 0 ? const Offset(1, 0) : v / v.distance;
