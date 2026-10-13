import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

/// A lift's demo baked as a sprite sheet: [frameCount] frames, left to right
/// then top to bottom, [columns] per row, played at [fps] on a loop.
///
/// Each frame shows [window] of the shared [stage], so every lift draws the
/// lifter at the same size and on the same floor line. World rects are y-up:
/// `top` holds the lowest y. Regenerate the PNGs with `make sprites` after
/// editing a motion or a window.
class SpriteSheet {
  const SpriteSheet({
    required this.asset,
    required this.window,
    required this.frameCount,
    this.posterFrame = 0,
  });

  static const fps = 12;
  static const columns = 8;

  /// Sheet pixels per world unit — sharp at roughly 3× device pixels on a
  /// phone-width demo.
  static const pixelsPerUnit = 2.5;

  /// The world rect every demo is framed in.
  static const stage = Rect.fromLTRB(16, -8, 200, 204);

  final String asset;
  final Rect window;
  final int frameCount;

  /// The most instructive frame, shown still when animations are disabled.
  final int posterFrame;

  Duration get period => Duration(
        microseconds: frameCount * Duration.microsecondsPerSecond ~/ fps,
      );

  Size get frameSize =>
      Size(window.width * pixelsPerUnit, window.height * pixelsPerUnit);

  int get rows => (frameCount + columns - 1) ~/ columns;

  Size get sheetSize =>
      Size(frameSize.width * columns, frameSize.height * rows);

  /// Where frame [index] sits in the sheet, in sheet pixels.
  Rect frameRect(int index) => Rect.fromLTWH(
        (index % columns) * frameSize.width,
        (index ~/ columns) * frameSize.height,
        frameSize.width,
        frameSize.height,
      );

  /// Where a frame lands when the [stage] is fitted (contained, centered)
  /// in a box of [size] logical pixels.
  Rect destinationIn(Size size) {
    final scale = math.min(
      size.width / stage.width,
      size.height / stage.height,
    );
    final left = (size.width - stage.width * scale) / 2;
    final top = (size.height - stage.height * scale) / 2;
    return Rect.fromLTRB(
      left + (window.left - stage.left) * scale,
      top + (stage.bottom - window.bottom) * scale,
      left + (window.right - stage.left) * scale,
      top + (stage.bottom - window.top) * scale,
    );
  }
}

/// The demo sheet for [exerciseId], or null when that lift has none yet.
SpriteSheet? spriteSheetFor(String exerciseId) => spriteSheets[exerciseId];

/// Every baked demo, keyed by exercise id. Frame counts give each rep about
/// 2.5–3.5 s at [SpriteSheet.fps]; windows hug the lift's whole range of
/// motion with a small margin (the exporter fails if one clips).
const spriteSheets = <String, SpriteSheet>{
  'squat': SpriteSheet(
    asset: 'assets/sprites/squat.png',
    window: Rect.fromLTRB(66, -6, 148, 158),
    frameCount: 38,
    posterFrame: 22,
  ),
  'pause_squat': SpriteSheet(
    asset: 'assets/sprites/pause_squat.png',
    window: Rect.fromLTRB(66, -6, 148, 158),
    frameCount: 50,
    posterFrame: 28,
  ),
  'front_squat': SpriteSheet(
    asset: 'assets/sprites/front_squat.png',
    window: Rect.fromLTRB(66, -6, 134, 162),
    frameCount: 38,
    posterFrame: 22,
  ),
  'lunge': SpriteSheet(
    asset: 'assets/sprites/lunge.png',
    window: Rect.fromLTRB(40, -6, 148, 156),
    frameCount: 38,
    posterFrame: 21,
  ),
  'good_morning': SpriteSheet(
    asset: 'assets/sprites/good_morning.png',
    window: Rect.fromLTRB(64, -6, 170, 160),
    frameCount: 41,
    posterFrame: 22,
  ),
  'bench_press': SpriteSheet(
    asset: 'assets/sprites/bench_press.png',
    window: Rect.fromLTRB(38, -6, 186, 122),
    frameCount: 36,
    posterFrame: 19,
  ),
  'pause_bench': SpriteSheet(
    asset: 'assets/sprites/pause_bench.png',
    window: Rect.fromLTRB(38, -6, 186, 122),
    frameCount: 48,
    posterFrame: 24,
  ),
  'close_grip_bench': SpriteSheet(
    asset: 'assets/sprites/close_grip_bench.png',
    window: Rect.fromLTRB(38, -6, 186, 126),
    frameCount: 36,
    posterFrame: 19,
  ),
  'bench_feet_up': SpriteSheet(
    asset: 'assets/sprites/bench_feet_up.png',
    window: Rect.fromLTRB(38, -6, 192, 122),
    frameCount: 36,
    posterFrame: 19,
  ),
  'incline_bench': SpriteSheet(
    asset: 'assets/sprites/incline_bench.png',
    window: Rect.fromLTRB(39, -6, 185, 140),
    frameCount: 36,
    posterFrame: 19,
  ),
  'db_bench': SpriteSheet(
    asset: 'assets/sprites/db_bench.png',
    window: Rect.fromLTRB(38, -6, 186, 112),
    frameCount: 36,
    posterFrame: 19,
  ),
  'skullcrusher': SpriteSheet(
    asset: 'assets/sprites/skullcrusher.png',
    window: Rect.fromLTRB(38, -6, 186, 114),
    frameCount: 36,
    posterFrame: 19,
  ),
  'barbell_row': SpriteSheet(
    asset: 'assets/sprites/barbell_row.png',
    window: Rect.fromLTRB(52, -6, 156, 108),
    frameCount: 31,
    posterFrame: 13,
  ),
  'db_row': SpriteSheet(
    asset: 'assets/sprites/db_row.png',
    window: Rect.fromLTRB(24, -6, 168, 112),
    frameCount: 34,
    posterFrame: 16,
  ),
  'seated_cable_row': SpriteSheet(
    asset: 'assets/sprites/seated_cable_row.png',
    window: Rect.fromLTRB(38, -6, 188, 144),
    frameCount: 36,
    posterFrame: 17,
  ),
  'seated_lever_row': SpriteSheet(
    asset: 'assets/sprites/seated_lever_row.png',
    window: Rect.fromLTRB(60, -6, 176, 180),
    frameCount: 36,
    posterFrame: 17,
  ),
  'lat_pulldown': SpriteSheet(
    asset: 'assets/sprites/lat_pulldown.png',
    window: Rect.fromLTRB(48, -6, 164, 198),
    frameCount: 36,
    posterFrame: 17,
  ),
  'overhead_press': SpriteSheet(
    asset: 'assets/sprites/overhead_press.png',
    window: Rect.fromLTRB(67, -6, 143, 186),
    frameCount: 38,
  ),
  'push_press': SpriteSheet(
    asset: 'assets/sprites/push_press.png',
    window: Rect.fromLTRB(67, -6, 143, 186),
    frameCount: 36,
    posterFrame: 7,
  ),
  'db_overhead_press_seated': SpriteSheet(
    asset: 'assets/sprites/db_overhead_press_seated.png',
    window: Rect.fromLTRB(68, -6, 166, 146),
    frameCount: 38,
    posterFrame: 17,
  ),
  'deadlift': SpriteSheet(
    asset: 'assets/sprites/deadlift.png',
    window: Rect.fromLTRB(54, -6, 150, 160),
    frameCount: 43,
  ),
  'pause_deadlift': SpriteSheet(
    asset: 'assets/sprites/pause_deadlift.png',
    window: Rect.fromLTRB(54, -6, 150, 160),
    frameCount: 53,
    posterFrame: 16,
  ),
  'romanian_deadlift': SpriteSheet(
    asset: 'assets/sprites/romanian_deadlift.png',
    window: Rect.fromLTRB(58, -6, 164, 160),
    frameCount: 41,
    posterFrame: 22,
  ),
  'sumo_deadlift': SpriteSheet(
    asset: 'assets/sprites/sumo_deadlift.png',
    window: Rect.fromLTRB(72, -6, 144, 158),
    frameCount: 43,
  ),
  'barbell_curl': SpriteSheet(
    asset: 'assets/sprites/barbell_curl.png',
    window: Rect.fromLTRB(76, -6, 134, 162),
    frameCount: 34,
    posterFrame: 15,
  ),
  'hammer_curl': SpriteSheet(
    asset: 'assets/sprites/hammer_curl.png',
    window: Rect.fromLTRB(76, -6, 134, 162),
    frameCount: 34,
    posterFrame: 15,
  ),
  'lateral_raise': SpriteSheet(
    asset: 'assets/sprites/lateral_raise.png',
    window: Rect.fromLTRB(34, -6, 166, 158),
    frameCount: 36,
    posterFrame: 17,
  ),
  'triceps_pushdown': SpriteSheet(
    asset: 'assets/sprites/triceps_pushdown.png',
    window: Rect.fromLTRB(76, -6, 164, 186),
    frameCount: 31,
    posterFrame: 14,
  ),
  'pallof_press': SpriteSheet(
    asset: 'assets/sprites/pallof_press.png',
    window: Rect.fromLTRB(76, -6, 170, 156),
    frameCount: 43,
    posterFrame: 19,
  ),
  'dips': SpriteSheet(
    asset: 'assets/sprites/dips.png',
    window: Rect.fromLTRB(49, -6, 143, 186),
    frameCount: 36,
    posterFrame: 17,
  ),
  'pull_up': SpriteSheet(
    asset: 'assets/sprites/pull_up.png',
    window: Rect.fromLTRB(78, -6, 154, 196),
    frameCount: 38,
    posterFrame: 17,
  ),
  'chin_up': SpriteSheet(
    asset: 'assets/sprites/chin_up.png',
    window: Rect.fromLTRB(78, -6, 154, 200),
    frameCount: 38,
    posterFrame: 17,
  ),
  'hanging_leg_raise': SpriteSheet(
    asset: 'assets/sprites/hanging_leg_raise.png',
    window: Rect.fromLTRB(56, -6, 196, 186),
    frameCount: 38,
    posterFrame: 18,
  ),
  'situps': SpriteSheet(
    asset: 'assets/sprites/situps.png',
    window: Rect.fromLTRB(18, -4, 190, 108),
    frameCount: 36,
    posterFrame: 17,
  ),
  'plank': SpriteSheet(
    asset: 'assets/sprites/plank.png',
    window: Rect.fromLTRB(18, -4, 190, 62),
    frameCount: 29,
    posterFrame: 7,
  ),
  'leg_press': SpriteSheet(
    asset: 'assets/sprites/leg_press.png',
    window: Rect.fromLTRB(18, -6, 172, 106),
    frameCount: 36,
    posterFrame: 2,
  ),
  'calf_raise': SpriteSheet(
    asset: 'assets/sprites/calf_raise.png',
    window: Rect.fromLTRB(56, -6, 138, 176),
    frameCount: 29,
    posterFrame: 13,
  ),
};
