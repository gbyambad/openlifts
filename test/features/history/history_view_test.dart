import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/history/application/history_view.dart';
import 'package:openlifts/features/history/presentation/history_screen.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';

void main() {
  testWidgets('empty state when there is no history', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryView(
            entries: const [],
            unit: Unit.kg,
            loadExercises: (_) async => [],
          ),
        ),
      ),
    );
    expect(find.textContaining('No workouts yet'), findsOneWidget);
  });

  testWidgets('renders a tile per workout with summary', (tester) async {
    final entries = [
      HistoryEntry(
        sessionId: 1,
        date: DateTime(2026, 3, 5),
        dayName: 'Workout A',
        setsLogged: 5,
        topSetKg: 62.5,
        totalVolumeKg: 612.5,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryView(
            entries: entries,
            unit: Unit.kg,
            loadExercises: (_) async => [],
          ),
        ),
      ),
    );

    expect(find.text('Workout A'), findsOneWidget);
    expect(find.textContaining('5 sets'), findsOneWidget);
    expect(find.textContaining('613 kg vol'), findsOneWidget); // 612.5 -> 613
    expect(find.text('Mar 5'), findsOneWidget);
  });

  testWidgets('tapping a tile loads and shows its exercises', (tester) async {
    final entries = [
      HistoryEntry(
        sessionId: 7,
        date: DateTime(2026, 3, 5),
        dayName: 'Workout A',
        setsLogged: 5,
        topSetKg: 60,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryView(
            entries: entries,
            unit: Unit.kg,
            loadExercises: (id) async => [
              SessionExercise(name: 'Squat ($id)', summary: '5·5·5 · 60 kg'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Squat (7)'), findsNothing); // collapsed
    await tester.tap(find.text('Workout A'));
    await tester.pumpAndSettle();
    expect(find.text('Squat (7)'), findsOneWidget);
    expect(find.text('5·5·5 · 60 kg'), findsOneWidget);
  });

  testWidgets('shows an error message when loading exercises fails',
      (tester) async {
    final entries = [
      HistoryEntry(
        sessionId: 7,
        date: DateTime(2026, 3, 5),
        dayName: 'Workout A',
        setsLogged: 5,
        topSetKg: 60,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HistoryView(
            entries: entries,
            unit: Unit.kg,
            loadExercises: (_) async => throw Exception('boom'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Workout A'));
    await tester.pumpAndSettle();
    expect(find.textContaining("Couldn't load exercises"), findsOneWidget);
  });
}
