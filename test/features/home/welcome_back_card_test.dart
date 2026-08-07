import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/home/application/welcome_back.dart';
import 'package:openlifts/features/home/presentation/welcome_back_card.dart';

import '../../support/test_app.dart';

/// Pumps the card with recording callbacks. `applied` collects each applied
/// percent; `dismissed` counts dismiss taps. Both are live references so
/// assertions read state captured after the taps.
Future<({List<int> applied, List<void> dismissed})> _pumpCard(
  WidgetTester tester, {
  required int suggestedPercent,
  int daysAway = 40,
}) async {
  final applied = <int>[];
  final dismissed = <void>[];
  await tester.pumpWidget(
    wrapWithLocalizations(
      Scaffold(
        body: WelcomeBackCard(
          suggestion: WelcomeBack(
            daysAway: daysAway,
            suggestedPercent: suggestedPercent,
          ),
          onApply: applied.add,
          onDismiss: () => dismissed.add(null),
        ),
      ),
    ),
  );
  return (applied: applied, dismissed: dismissed);
}

void main() {
  testWidgets('prefills the suggested percent and applies it', (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 20);
    expect(find.text('20%'), findsOneWidget);

    await tester.tap(find.text('Apply deload'));
    await tester.pump();

    expect(rec.applied, [20]);
    expect(rec.dismissed, isEmpty);
  });

  testWidgets('the stepper adjusts the percent in 5% steps', (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 20);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('15%'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('25%'), findsOneWidget);

    await tester.tap(find.text('Apply deload'));
    await tester.pump();
    expect(rec.applied, [25]);
  });

  testWidgets('the minus button is disabled at 0%', (tester) async {
    await _pumpCard(tester, suggestedPercent: 5);

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);

    // Disabled at the floor: another tap can't go negative.
    final minus = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.remove),
        matching: find.byType(IconButton),
      ),
    );
    expect(minus.onPressed, isNull);
  });

  testWidgets('the plus button is disabled at the 50% ceiling', (tester) async {
    await _pumpCard(tester, suggestedPercent: 50);
    expect(find.text('50%'), findsOneWidget);

    final plus = tester.widget<IconButton>(
      find.ancestor(
        of: find.byIcon(Icons.add),
        matching: find.byType(IconButton),
      ),
    );
    expect(plus.onPressed, isNull);
  });

  testWidgets('"Keep weights" dismisses without applying', (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 20);

    await tester.tap(find.text('Keep weights'));
    await tester.pump();

    expect(rec.dismissed, hasLength(1));
    expect(rec.applied, isEmpty);
  });

  testWidgets('stepping down to 0% turns "Apply deload" into a dismiss',
      (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 5);

    await tester.tap(find.byIcon(Icons.remove)); // 5% -> 0%
    await tester.pump();

    await tester.tap(find.text('Apply deload'));
    await tester.pump();

    // A 0% deload is meaningless, so applying just dismisses.
    expect(rec.applied, isEmpty);
    expect(rec.dismissed, hasLength(1));
  });

  testWidgets('a double-tap on "Apply deload" fires the deload only once',
      (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 20);

    // Two taps in the window before the parent tears the card down.
    await tester.tap(find.text('Apply deload'));
    await tester.tap(find.text('Apply deload'), warnIfMissed: false);
    await tester.pump();

    expect(rec.applied, [20]); // not [20, 20]
  });

  testWidgets('applying disables "Keep weights" too (no mixed double action)',
      (tester) async {
    final rec = await _pumpCard(tester, suggestedPercent: 20);

    await tester.tap(find.text('Apply deload'));
    await tester.tap(find.text('Keep weights'), warnIfMissed: false);
    await tester.pump();

    expect(rec.applied, [20]);
    expect(rec.dismissed, isEmpty);
  });
}
