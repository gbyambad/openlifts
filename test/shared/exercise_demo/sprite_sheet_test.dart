import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/shared/exercise_demo/exercise_motions.dart';
import 'package:openlifts/shared/exercise_demo/sprite_sheet.dart';

/// Width and height from a PNG's IHDR chunk, without decoding it.
(int, int) _pngSize(String path) {
  final header = ByteData.sublistView(File(path).readAsBytesSync(), 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  test('every sheet has a motion to bake it from', () {
    for (final id in spriteSheets.keys) {
      expect(exerciseMotionFor(id), isNotNull, reason: id);
    }
  });

  test('an unknown lift has no sheet', () {
    expect(spriteSheetFor('not_a_lift'), isNull);
  });

  test('every demo has a baked sheet', () {
    expect(spriteSheets.keys.toSet(), exerciseMotionIds.toSet());
  });

  for (final MapEntry(key: id, value: sheet) in spriteSheets.entries) {
    group(id, () {
      test('the baked PNG matches the declared layout (run make sprites)', () {
        final size = sheet.sheetSize;

        expect(
          _pngSize(sheet.asset),
          (size.width.round(), size.height.round()),
        );
      });

      test('frames are whole pixels and the window sits on the stage', () {
        final frame = sheet.frameSize;

        expect(frame.width, frame.width.roundToDouble());
        expect(frame.height, frame.height.roundToDouble());
        expect(
          SpriteSheet.stage.expandToInclude(sheet.window),
          SpriteSheet.stage,
        );
        expect(sheet.posterFrame, lessThan(sheet.frameCount));
      });
    });
  }

  test('frames run left to right, then wrap to the next row', () {
    const sheet = SpriteSheet(
      asset: 'x.png',
      window: Rect.fromLTRB(0, 0, 40, 80),
      frameCount: 10,
    );

    expect(sheet.frameRect(0), const Rect.fromLTWH(0, 0, 100, 200));
    expect(sheet.frameRect(9), const Rect.fromLTWH(100, 200, 100, 200));
    expect(sheet.rows, 2);
  });

  test('a frame lands where its window sits on the fitted stage', () {
    const stage = SpriteSheet.stage;
    const sheet = SpriteSheet(asset: 'x.png', window: stage, frameCount: 1);
    // Twice the stage's width and height: scale 2, no letterboxing.
    final box = Size(stage.width * 2, stage.height * 2);

    expect(sheet.destinationIn(box), Offset.zero & box);
  });
}
