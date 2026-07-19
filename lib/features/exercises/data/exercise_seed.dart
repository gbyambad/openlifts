import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';

/// Seeds the exercise catalog (and its muscle tags) from a JSON string — the
/// bundled `assets/seed/exercises.json`, or a fixture in tests.
///
/// Idempotent: insert-or-replace on the slug PK, so running it twice leaves
/// exactly one row per exercise. Exercises are inserted before their muscle
/// rows (FK order).
Future<void> seedExercisesFromJson(AppDatabase db, String jsonStr) async {
  final rows = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();

  await db.batch((batch) {
    batch.insertAll(
      db.exercises,
      rows.map(_toExercise).toList(),
      mode: InsertMode.insertOrReplace,
    );
    for (final e in rows) {
      final muscles =
          (e['muscles'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      batch.insertAll(
        db.exerciseMuscles,
        muscles
            .map(
              (m) => ExerciseMusclesCompanion.insert(
                exerciseId: e['id'] as String,
                muscle: Muscle.values.byName(m['name'] as String),
                isPrimary: Value(m['primary'] as bool? ?? false),
              ),
            )
            .toList(),
        mode: InsertMode.insertOrReplace,
      );
    }
  });
}

ExercisesCompanion _toExercise(Map<String, dynamic> e) {
  final pattern = e['movementPattern'] as String?;
  return ExercisesCompanion.insert(
    id: e['id'] as String,
    name: e['name'] as String,
    equipment: Equipment.values.byName(e['equipment'] as String),
    incrementKg: (e['incrementKg'] as num).toDouble(),
    movementPattern: Value(
      pattern == null ? null : MovementPattern.values.byName(pattern),
    ),
    startsLoaded: Value(e['startsLoaded'] as bool? ?? false),
    instructions: Value(
      (e['instructions'] as List?)?.cast<String>() ?? const [],
    ),
  );
}
