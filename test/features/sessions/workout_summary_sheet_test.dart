import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/sessions/presentation/workout_summary_sheet.dart';

void main() {
  testWidgets('the completion summary shows sets logged and total volume',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showWorkoutSummary(
                context,
                dayName: 'Workout A',
                setsDone: 5,
                volumeKg: 625,
                unit: Unit.kg,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Nice work!'), findsOneWidget);
    expect(find.text('Workout A complete'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Sets logged'), findsOneWidget);
    expect(find.text('625 kg'), findsOneWidget);
    expect(find.text('Total volume'), findsOneWidget);
  });
}
