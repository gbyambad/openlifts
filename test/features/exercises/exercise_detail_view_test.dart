import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/exercises/presentation/exercise_detail_screen.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<Exercise> insertSquat() async {
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'squat',
            name: 'Squat',
            equipment: Equipment.barbell,
            incrementKg: 2.5,
            instructions:
                const Value(['Unrack the bar', 'Squat down', 'Drive up']),
          ),
        );
    return (db.select(db.exercises)..where((t) => t.id.equals('squat')))
        .getSingle();
  }

  testWidgets('renders name and numbered instructions', (tester) async {
    final ex = await insertSquat();

    await tester.pumpWidget(
      MaterialApp(
        home:
            ExerciseDetailView(exercise: ex, history: const [], unit: Unit.kg),
      ),
    );

    expect(find.text('Squat'), findsWidgets); // app bar title
    expect(find.textContaining('Unrack the bar'), findsOneWidget);
    expect(find.textContaining('Drive up'), findsOneWidget);
    expect(find.text('How to perform'), findsOneWidget);
  });

  testWidgets('shows the current weight from history', (tester) async {
    final ex = await insertSquat();

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseDetailView(
          exercise: ex,
          history: [
            WeightPoint(date: DateTime(2026, 3, 2), weightKg: 60),
            WeightPoint(date: DateTime(2026, 3, 5), weightKg: 65),
          ],
          unit: Unit.kg,
        ),
      ),
    );

    expect(find.text('Current'), findsOneWidget);
    // 65 kg appears both as the current weight and in the recent list.
    expect(find.text('65 kg'), findsWidgets);
    expect(find.text('Recent top sets'), findsOneWidget);
    expect(find.text('60 kg'), findsOneWidget);
  });
}
