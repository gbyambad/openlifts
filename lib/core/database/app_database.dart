import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:openlifts/core/database/converters.dart';
import 'package:openlifts/core/database/tables.dart';

part 'app_database.g.dart';

/// The app's Drift database. Tables live here (cross-cutting infrastructure);
/// feature repositories query it behind their own interfaces.
///
/// Construct with a [QueryExecutor]: `driftDatabase(...)` in the app, or
/// `NativeDatabase.memory()` in tests.
@DriftDatabase(
  tables: [
    Exercises,
    ExerciseMuscles,
    Settings,
    LiftProgressEntries,
    Programs,
    ProgramDays,
    Prescriptions,
    SetGroups,
    WorkoutSessions,
    SetLogs,
    BodyweightEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  // Pre-release: the schema is created wholesale from the table definitions.
  // No onUpgrade steps yet — nothing has shipped to migrate from, so iterate
  // the schema freely. Add stepwise migrations once the app ships (see
  // AGENTS.md).
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
      );
}
