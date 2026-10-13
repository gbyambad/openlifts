import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/shared/exercise_demo/exercise_demo.dart';
import 'package:openlifts/shared/exercise_demo/sprite_sheet.dart';

import '../../support/test_app.dart';

Widget _demo({bool reduceMotion = false}) => wrapWithLocalizations(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(
            body: ExerciseDemo(
              sheet: spriteSheetFor('squat')!,
              exerciseName: 'Squat',
            ),
          ),
        ),
      ),
    );

final Finder _pausedBadge = find.byKey(const Key('exerciseDemoPaused'));

void main() {
  testWidgets('plays on open and pauses on tap', (tester) async {
    await tester.pumpWidget(_demo());
    expect(_pausedBadge, findsNothing);

    await tester.tap(find.byType(ExerciseDemo));
    await tester.pump();

    expect(_pausedBadge, findsOneWidget);
  });

  testWidgets('holds still under reduced motion until tapped', (tester) async {
    await tester.pumpWidget(_demo(reduceMotion: true));
    expect(_pausedBadge, findsOneWidget);

    await tester.tap(find.byType(ExerciseDemo));
    await tester.pump();

    expect(_pausedBadge, findsNothing);
  });

  testWidgets('is labelled for screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_demo());

    expect(
      find.bySemanticsLabel('Animated demonstration of Squat'),
      findsOneWidget,
    );
    handle.dispose();
  });
}
