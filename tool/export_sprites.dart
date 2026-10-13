// Bakes each lift's cartoon (LifterPainter) into the sprite sheet PNG the app
// plays. Painting needs the Flutter engine, hence running under `flutter test`:
//
//   make sprites
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:openlifts/shared/exercise_demo/exercise_motions.dart';
import 'package:openlifts/shared/exercise_demo/lifter_painter.dart';
import 'package:openlifts/shared/exercise_demo/sprite_sheet.dart';

void main() {
  for (final MapEntry(key: id, value: sheet) in spriteSheets.entries) {
    test('bake $id', () async {
      final motion = exerciseMotionFor(id)!;
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      for (var i = 0; i < sheet.frameCount; i++) {
        final frame = sheet.frameRect(i);
        canvas
          ..save()
          ..translate(frame.left, frame.top)
          ..clipRect(Offset.zero & frame.size);
        LifterPainter(
          motion: motion,
          t: i / sheet.frameCount,
          window: sheet.window,
        ).paint(canvas, frame.size);
        canvas.restore();
      }
      final size = sheet.sheetSize;
      final image = await recorder
          .endRecording()
          .toImage(size.width.round(), size.height.round());
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      ))!;

      _expectClearEdges(sheet, rgba, image.width);
      File(sheet.asset).writeAsBytesSync(
        _indexedPng(rgba.buffer.asUint8List(), image.width, image.height),
      );
    });
  }
}

/// Paint on a frame's border means the window clips the lift: widen it.
void _expectClearEdges(SpriteSheet sheet, ByteData rgba, int stride) {
  bool opaque(int x, int y) => rgba.getUint8((y * stride + x) * 4 + 3) > 0;

  for (var i = 0; i < sheet.frameCount; i++) {
    final f = sheet.frameRect(i);
    final (left, top) = (f.left.round(), f.top.round());
    final (right, bottom) = (f.right.round() - 1, f.bottom.round() - 1);
    for (var x = left; x <= right; x++) {
      expect(
        opaque(x, top) || opaque(x, bottom),
        isFalse,
        reason: '${sheet.asset} frame $i touches its top/bottom edge',
      );
    }
    for (var y = top; y <= bottom; y++) {
      expect(
        opaque(left, y) || opaque(right, y),
        isFalse,
        reason: '${sheet.asset} frame $i touches its left/right edge',
      );
    }
  }
}

/// Encodes straight-alpha [rgba] as a 256-color palette PNG — about a fifth
/// the size of full RGBA, and flat cartoon art loses nothing visible.
Uint8List _indexedPng(Uint8List rgba, int width, int height) {
  final (:palette, :indices) = _quantize(rgba);
  final image = img.Image(
    width: width,
    height: height,
    numChannels: 1,
    palette: img.PaletteUint8(palette.length, 4),
  );
  for (var i = 0; i < palette.length; i++) {
    final c = palette[i];
    image.palette!.setRgba(
      i,
      c >> 24,
      (c >> 16) & 0xFF,
      (c >> 8) & 0xFF,
      c & 0xFF,
    );
  }
  image.buffer.asUint8List().setAll(0, indices);
  return img.encodePng(image, level: 9, filter: img.PngFilter.none);
}

/// Median-cut quantization over RGBA. The stock quantizers in package:image
/// drop alpha, which the sprites' anti-aliased edges need. Index 0 is kept
/// for fully transparent pixels.
({List<int> palette, Uint8List indices}) _quantize(Uint8List rgba) {
  int channel(int color, int c) => (color >> (24 - 8 * c)) & 0xFF;

  final pixels = rgba.length ~/ 4;
  final colors = Uint32List(pixels);
  final counts = <int, int>{};
  for (var i = 0; i < pixels; i++) {
    final o = i * 4;
    final a = rgba[o + 3];
    final color = a == 0
        ? 0
        : (rgba[o] << 24) | (rgba[o + 1] << 16) | (rgba[o + 2] << 8) | a;
    colors[i] = color;
    if (color != 0) counts[color] = (counts[color] ?? 0) + 1;
  }

  // The widest channel of a box, and its range.
  (int, int) widest(List<int> box) {
    var best = (0, -1);
    for (var c = 0; c < 4; c++) {
      var lo = 255;
      var hi = 0;
      for (final color in box) {
        final v = channel(color, c);
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      if (hi - lo > best.$2) best = (c, hi - lo);
    }
    return best;
  }

  int weight(List<int> box) => box.fold(0, (sum, c) => sum + counts[c]!);

  // Repeatedly halve the box whose widest range, weighted by the pixels it
  // covers, is largest — so busy, heavily used colors get the entries.
  final boxes = [counts.keys.toList()];
  while (boxes.length < 255) {
    var pick = -1;
    var pickScore = 0;
    for (var i = 0; i < boxes.length; i++) {
      if (boxes[i].length < 2) continue;
      final score = widest(boxes[i]).$2 * weight(boxes[i]);
      if (score > pickScore) (pick, pickScore) = (i, score);
    }
    if (pick < 0) break;
    final box = boxes[pick];
    final (c, _) = widest(box);
    box.sort((a, b) => channel(a, c).compareTo(channel(b, c)));
    final half = weight(box) / 2;
    var run = 0;
    var cut = 1;
    for (; cut < box.length - 1; cut++) {
      run += counts[box[cut - 1]]!;
      if (run >= half) break;
    }
    boxes
      ..[pick] = box.sublist(0, cut)
      ..add(box.sublist(cut));
  }

  final palette = <int>[0];
  final index = <int, int>{0: 0};
  for (final box in boxes) {
    final sums = [0, 0, 0, 0];
    var total = 0;
    for (final color in box) {
      final n = counts[color]!;
      total += n;
      for (var c = 0; c < 4; c++) {
        sums[c] += channel(color, c) * n;
      }
      index[color] = palette.length;
    }
    palette.add(
      sums.fold(0, (packed, s) => packed << 8 | (s / total).round()),
    );
  }

  final indices = Uint8List(pixels);
  for (var i = 0; i < pixels; i++) {
    indices[i] = index[colors[i]]!;
  }
  return (palette: palette, indices: indices);
}
