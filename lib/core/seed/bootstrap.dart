import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart' show rootBundle;
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/exercises/data/exercise_seed.dart';
import 'package:openlifts/features/programs/data/program_repository_impl.dart';
import 'package:openlifts/features/programs/data/program_seed.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

/// Bump when the bundled built-in content changes so it re-applies.
/// v2: added program category tags.
const currentSeedVersion = 2;

/// Seeds exercises (and their muscles) then the built-in programs — exercises
/// before programs (FK order). Idempotent via slug PKs.
Future<void> runSeed(
  AppDatabase db, {
  required String exercisesJson,
  required String programsJson,
}) async {
  await seedExercisesFromJson(db, exercisesJson);
  await seedProgramsFromJson(DriftProgramRepository(db), programsJson);
}

/// Runs the seed only when the stored `seedVersion` is behind, then records it.
/// Re-applying updated built-ins never clobbers user data — copy-on-edit keeps
/// custom programs separate.
Future<void> ensureSeeded(
  AppDatabase db, {
  required String exercisesJson,
  required String programsJson,
}) async {
  final settings = DriftSettingsRepository(db);
  final current = await settings.get();
  if (current.seedVersion >= currentSeedVersion) return;
  await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
  await settings
      .save(const SettingsCompanion(seedVersion: Value(currentSeedVersion)));
}

/// App entry point for seeding: loads the bundled assets and seeds. Call once
/// at startup (after `WidgetsFlutterBinding.ensureInitialized`).
Future<void> ensureSeededFromAssets(AppDatabase db) async {
  final [exercisesJson, programsJson] = await Future.wait([
    rootBundle.loadString('assets/seed/exercises.json'),
    rootBundle.loadString('assets/seed/programs.json'),
  ]);
  await ensureSeeded(
    db,
    exercisesJson: exercisesJson,
    programsJson: programsJson,
  );
}
