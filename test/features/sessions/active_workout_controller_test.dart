import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/progression/data/lift_progress_repository_impl.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

Future<(AppDatabase, ProviderContainer)> _seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
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
  return (db, container);
}

void main() {
  test('finishing a fully-successful workout advances each lift weight',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final state =
        await container.read(activeWorkoutControllerProvider('sl5x5-a').future);
    final notifier =
        container.read(activeWorkoutControllerProvider('sl5x5-a').notifier);
    for (var li = 0; li < state.lifts.length; li++) {
      for (final ws in state.lifts[li].workingSets) {
        notifier.logReps(li, ws.index, ws.targetReps);
      }
    }
    await notifier.finish();

    // Squat had no prior progress -> default anchor 20 -> +2.5 = 22.5.
    final squat = await DriftLiftProgressRepository(db).get('squat');
    expect(squat!.workingWeightKg, 22.5);
  });

  test('a short set does not increment and records a failure', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final state =
        await container.read(activeWorkoutControllerProvider('sl5x5-a').future);
    final notifier =
        container.read(activeWorkoutControllerProvider('sl5x5-a').notifier);
    for (final ws in state.lifts[0].workingSets) {
      notifier.logReps(0, ws.index, 0); // squat sets all short
    }
    await notifier.finish();

    final squat = await DriftLiftProgressRepository(db).get('squat');
    expect(squat!.workingWeightKg, 20); // unchanged
    expect(squat.consecutiveFailures, 1);
  });

  test('editing the working weight re-resolves sets and drives progression',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = activeWorkoutControllerProvider('sl5x5-a');
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    // The notifier calls in this test are separated by asserts and a loop, so
    // they can't be written as a cascade.
    // ignore: cascade_invocations
    notifier.setLiftWeight(0, 50); // squat 20 -> 50
    final edited = container.read(provider).value!.lifts[0];
    expect(edited.anchorKg, 50);
    expect(edited.workingSets.every((ws) => ws.weightKg == 50), isTrue);

    for (final ws in edited.workingSets) {
      notifier.logReps(0, ws.index, ws.targetReps);
    }
    await notifier.finish();

    final squat = await DriftLiftProgressRepository(db).get('squat');
    expect(squat!.workingWeightKg, 52.5); // 50 + 2.5, from the edited weight
  });

  test('setSetWeight overrides one set only, keeping the anchor and others',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = activeWorkoutControllerProvider('sl5x5-a');
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);

    final before = container.read(provider).value!.lifts[0];
    expect(before.workingSets.length, greaterThan(1));
    final originalOthers =
        before.workingSets.skip(1).map((ws) => ws.weightKg).toList();

    notifier.setSetWeight(0, 0, 42.5); // just the top set

    final after = container.read(provider).value!.lifts[0];
    expect(after.anchorKg, before.anchorKg); // anchor untouched
    expect(after.workingSets[0].weightKg, 42.5);
    expect(
      after.workingSets.skip(1).map((ws) => ws.weightKg).toList(),
      originalOthers, // back-off sets untouched
    );
  });

  test('logBodyweight persists and shows as the current bodyweight', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = activeWorkoutControllerProvider('sl5x5-a');
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    expect(container.read(provider).value!.bodyweightKg, isNull);

    await notifier.logBodyweight(72.5);

    // Reflected in state immediately…
    expect(container.read(provider).value!.bodyweightKg, 72.5);
    // …and a fresh load picks it up as the latest entry.
    final reloaded =
        await container.read(activeWorkoutControllerProvider('sl5x5-b').future);
    expect(reloaded.bodyweightKg, 72.5);
  });

  test('cycling a set steps reps target → 0 → unlogged', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = activeWorkoutControllerProvider('sl5x5-a');
    await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    int? reps() =>
        container.read(provider).value!.lifts[0].workingSets[0].actualReps;

    expect(reps(), isNull); // not logged
    notifier.cycleSet(0, 0);
    expect(reps(), 5); // first tap = target reps
    notifier.cycleSet(0, 0);
    expect(reps(), 4);
    for (var i = 0; i < 4; i++) {
      notifier.cycleSet(0, 0);
    }
    expect(reps(), 0); // stepped down to zero
    notifier.cycleSet(0, 0);
    expect(reps(), isNull); // back to unlogged
  });

  test('add and remove set change the working-set count', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = activeWorkoutControllerProvider('sl5x5-a');
    final state = await container.read(provider.future);
    final notifier = container.read(provider.notifier);
    final before = state.lifts[0].workingSets.length;

    notifier.addSet(0);
    expect(
      container.read(provider).value!.lifts[0].workingSets.length,
      before + 1,
    );

    notifier
      ..removeSet(0)
      ..removeSet(0);
    expect(
      container.read(provider).value!.lifts[0].workingSets.length,
      before - 1,
    );
  });
}
