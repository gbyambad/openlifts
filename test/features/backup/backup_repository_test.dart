import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/backup/data/backup_repository_impl.dart';
import 'package:openlifts/features/backup/domain/backup_repository.dart';
import 'package:openlifts/features/bodyweight/data/bodyweight_repository_impl.dart';
import 'package:openlifts/features/programs/data/program_repository_impl.dart';
import 'package:openlifts/features/sessions/data/session_repository_impl.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

import '../../support/test_database.dart';

Future<String> _asset(String path) => File(path).readAsString();

void main() {
  late AppDatabase db;
  late DriftBackupRepository backup;
  late DriftProgramRepository programs;
  late String exercisesJson;
  late String programsJson;

  setUp(() async {
    db = openTestDb();
    backup = DriftBackupRepository(db);
    programs = DriftProgramRepository(db);
    exercisesJson = await _asset('assets/seed/exercises.json');
    programsJson = await _asset('assets/seed/programs.json');
    await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
  });
  tearDown(() => db.close());

  /// Builds a realistic user state on top of the seeded built-ins.
  Future<void> seedUserData() async {
    // A custom (forked) program.
    await programs.copyAsCustom(
      'stronglifts-5x5',
      newId: 'mine',
      newName: 'Mine',
    );
    final dayId = (await programs.loadTree('mine'))!.days.first.day.id;

    // A custom exercise + its muscle tag.
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'pause-squat',
            name: 'Pause Squat',
            equipment: Equipment.barbell,
            incrementKg: 2.5,
            isCustom: const Value(true),
          ),
        );
    await db.into(db.exerciseMuscles).insert(
          ExerciseMusclesCompanion.insert(
            exerciseId: 'pause-squat',
            muscle: Muscle.quads,
            isPrimary: const Value(true),
          ),
        );

    // Progression state, a completed session with sets, and bodyweight.
    await db.into(db.liftProgressEntries).insert(
          LiftProgressEntriesCompanion.insert(
            exerciseId: 'pause-squat',
            workingWeightKg: 62.5,
            updatedAt: DateTime(2026, 3),
          ),
        );
    final sessions = DriftSessionRepository(db);
    final sid = await sessions.startSession(dayId, DateTime(2026, 3));
    await sessions.logSet(
      sessionId: sid,
      exerciseId: 'pause-squat',
      setIndex: 0,
      weightKg: 62.5,
      targetReps: 5,
      actualReps: 5,
    );
    await sessions.completeSession(sid, DateTime(2026, 3, 1, 1));
    await DriftBodyweightRepository(db).add(DateTime(2026, 3, 2), 80);

    await DriftSettingsRepository(db).save(
      const SettingsCompanion(
        unit: Value(Unit.lb),
        activeProgramId: Value('mine'),
      ),
    );
  }

  test('round-trips user data and re-seeds built-ins', () async {
    await seedUserData();

    final json = await backup.exportToJson();
    await backup.restoreFromJson(
      json,
      exercisesSeed: exercisesJson,
      programsSeed: programsJson,
    );

    // Built-ins re-seeded (8) plus the one custom program.
    final all = await programs.all();
    expect(all.length, 9);
    expect(all.any((p) => p.id == 'mine' && !p.isBuiltIn), isTrue);

    // Custom program tree restored with foreign keys remapped intact.
    final tree = await programs.loadTree('mine');
    expect(tree, isNotNull);
    expect(tree!.days, isNotEmpty);
    expect(tree.days.first.prescriptions, isNotEmpty);
    expect(tree.days.first.prescriptions.first.setGroups, isNotEmpty);

    // Custom exercise + muscle.
    final customEx = await (db.select(db.exercises)
          ..where((t) => t.id.equals('pause-squat')))
        .getSingleOrNull();
    expect(customEx?.isCustom, isTrue);

    // Progression, session, set log, bodyweight, settings.
    final lp = await (db.select(db.liftProgressEntries)
          ..where((t) => t.exerciseId.equals('pause-squat')))
        .getSingle();
    expect(lp.workingWeightKg, 62.5);

    final sessionRows = await db.select(db.workoutSessions).get();
    expect(sessionRows, hasLength(1));
    expect(sessionRows.single.completedAt, isNotNull);

    final logs = await db.select(db.setLogs).get();
    expect(logs, hasLength(1));
    expect(logs.single.weightKg, 62.5);
    expect(logs.single.exerciseId, 'pause-squat');

    final bw = await db.select(db.bodyweightEntries).get();
    expect(bw, hasLength(1));
    expect(bw.single.weightKg, 80);

    final settings = await DriftSettingsRepository(db).get();
    expect(settings.unit, Unit.lb);
    expect(settings.activeProgramId, 'mine');
  });

  test('rejects a backup from a newer app and changes nothing', () async {
    await seedUserData();

    final newer = jsonEncode({
      'header': {
        'exportVersion': backupExportVersion + 1,
        'schemaVersion': db.schemaVersion,
        'appVersion': '99.0',
        'exportedAt': 0,
      },
    });

    expect(
      () => backup.validate(newer),
      throwsA(isA<IncompatibleBackupException>()),
    );
    await expectLater(
      backup.restoreFromJson(
        newer,
        exercisesSeed: exercisesJson,
        programsSeed: programsJson,
      ),
      throwsA(isA<IncompatibleBackupException>()),
    );

    // Untouched: the custom program still exists.
    expect((await programs.all()).any((p) => p.id == 'mine'), isTrue);
  });

  test('aborts on a corrupt file, leaving existing data intact', () async {
    await seedUserData();
    final json = await backup.exportToJson();
    final truncated = json.substring(0, json.length ~/ 2);

    await expectLater(
      backup.restoreFromJson(
        truncated,
        exercisesSeed: exercisesJson,
        programsSeed: programsJson,
      ),
      throwsA(isA<CorruptBackupException>()),
    );

    // Transaction rolled back: original data still present.
    final bw = await db.select(db.bodyweightEntries).get();
    expect(bw, hasLength(1));
    expect((await programs.all()).any((p) => p.id == 'mine'), isTrue);
  });
}
