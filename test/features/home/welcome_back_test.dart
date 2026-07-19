import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/home/application/welcome_back.dart';
import 'package:openlifts/features/progression/data/lift_progress_repository_impl.dart';
import 'package:openlifts/features/sessions/data/session_repository_impl.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

(AppDatabase, ProviderContainer) _setup() {
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  return (db, container);
}

Future<void> _lastWorkout(AppDatabase db, {required int daysAgo}) async {
  final when = DateTime.now().subtract(Duration(days: daysAgo));
  final sessions = DriftSessionRepository(db);
  final id = await sessions.startSession('dayA', when);
  await sessions.completeSession(id, when);
}

void main() {
  test('suggests a deload after a layoff, scaled by time away', () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await DriftSettingsRepository(db)
        .save(const SettingsCompanion(activeProgramId: Value('prog')));
    await _lastWorkout(db, daysAgo: 40); // ~1–2 months -> 20%
    await DriftLiftProgressRepository(db).upsert(
      exerciseId: 'squat',
      workingWeightKg: 100,
      updatedAt: DateTime.now(),
    );

    final suggestion = await container.read(welcomeBackProvider.future);
    expect(suggestion, isNotNull);
    expect(suggestion!.suggestedPercent, 20);
  });

  test('no suggestion for a short break', () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await DriftSettingsRepository(db)
        .save(const SettingsCompanion(activeProgramId: Value('prog')));
    await _lastWorkout(db, daysAgo: 5);
    await DriftLiftProgressRepository(db).upsert(
      exerciseId: 'squat',
      workingWeightKg: 100,
      updatedAt: DateTime.now(),
    );

    expect(await container.read(welcomeBackProvider.future), isNull);
  });

  test('applyDeload lowers all working weights and stops re-prompting',
      () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await DriftSettingsRepository(db)
        .save(const SettingsCompanion(activeProgramId: Value('prog')));
    await _lastWorkout(db, daysAgo: 40);
    final progress = DriftLiftProgressRepository(db);
    await progress.upsert(
      exerciseId: 'squat',
      workingWeightKg: 100,
      consecutiveFailures: 2,
      updatedAt: DateTime.now(),
    );

    await container
        .read(welcomeBackControllerProvider.notifier)
        .applyDeload(20);

    final squat = await progress.get('squat');
    expect(squat!.workingWeightKg, 80); // 100 - 20%, snapped to loadable
    expect(squat.consecutiveFailures, 0); // streak reset

    // The layoff is now handled — no repeat prompt.
    expect(await container.read(welcomeBackProvider.future), isNull);
  });

  test('dismiss keeps weights but stops re-prompting', () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await DriftSettingsRepository(db)
        .save(const SettingsCompanion(activeProgramId: Value('prog')));
    await _lastWorkout(db, daysAgo: 40);
    final progress = DriftLiftProgressRepository(db);
    await progress.upsert(
      exerciseId: 'squat',
      workingWeightKg: 100,
      updatedAt: DateTime.now(),
    );

    await container.read(welcomeBackControllerProvider.notifier).dismiss();

    // Weights untouched by a dismiss...
    expect((await progress.get('squat'))!.workingWeightKg, 100);
    // ...but the layoff is handled, so no repeat prompt.
    expect(await container.read(welcomeBackProvider.future), isNull);
  });

  test('re-prompts for a new layoff after a fresh workout', () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final settings = DriftSettingsRepository(db);
    await settings.save(
      const SettingsCompanion(activeProgramId: Value('prog')),
    );
    await DriftLiftProgressRepository(db).upsert(
      exerciseId: 'squat',
      workingWeightKg: 100,
      updatedAt: DateTime.now(),
    );

    // A deload was handled 50 days ago, but the user has since trained again
    // (last workout 25 days ago) and taken a new break -> a new layoff.
    await _lastWorkout(db, daysAgo: 25);
    final handledAt = DateTime.now().subtract(const Duration(days: 50));
    await settings.save(
      SettingsCompanion(deloadHandledAt: Value(handledAt)),
    );

    final suggestion = await container.read(welcomeBackProvider.future);
    expect(suggestion, isNotNull); // handled predates the last workout
    expect(suggestion!.suggestedPercent, 10); // ~25 days -> 10%
  });

  test('no suggestion when no working weights are recorded', () async {
    final (db, container) = _setup();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await DriftSettingsRepository(db)
        .save(const SettingsCompanion(activeProgramId: Value('prog')));
    await _lastWorkout(db, daysAgo: 40); // long layoff...
    // ...but no lift progress rows, so there is nothing to deload.

    expect(await container.read(welcomeBackProvider.future), isNull);
  });
}
