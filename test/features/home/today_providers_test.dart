import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

// Integration test: plain `test()` (real async) exercises the provider over an
// in-memory DB. Widget tests override todayProvider with a fixed value instead.
void main() {
  test('today assembles the active program next day with lift weights',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await runSeed(
      db,
      exercisesJson: await File('assets/seed/exercises.json').readAsString(),
      programsJson: await File('assets/seed/programs.json').readAsString(),
    );
    await DriftSettingsRepository(db).save(
      const SettingsCompanion(activeProgramId: Value('stronglifts-5x5')),
    );

    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final view = await container.read(todayProvider.future);
    expect(view, isNotNull);
    expect(view!.workouts, isNotEmpty);
    final next = view.workouts.first;
    expect(next.dayName, 'Workout A'); // fresh start -> first day
    expect(
      next.exercises.map((e) => e.name),
      containsAll(['Squat', 'Bench Press', 'Barbell Row']),
    );
    // Each exercise carries a concrete load string (e.g. "5×5 20 kg").
    expect(next.exercises.every((e) => e.scheme.contains('kg')), isTrue);
  });

  test('today is null with no active program', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    expect(await container.read(todayProvider.future), isNull);
  });
}
