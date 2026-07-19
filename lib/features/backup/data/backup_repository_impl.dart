import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/backup/data/backup_codec.dart';
import 'package:openlifts/features/backup/domain/backup_repository.dart';

/// Drift-backed [BackupRepository].
class DriftBackupRepository implements BackupRepository {
  DriftBackupRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> exportToJson() async {
    final settings = await _db.select(_db.settings).getSingleOrNull();

    final customExercises = await (_db.select(_db.exercises)
          ..where((t) => t.isCustom.equals(true)))
        .get();
    final exerciseIds = customExercises.map((e) => e.id).toList();
    final muscles = exerciseIds.isEmpty
        ? <ExerciseMuscle>[]
        : await (_db.select(_db.exerciseMuscles)
              ..where((t) => t.exerciseId.isIn(exerciseIds)))
            .get();

    final customPrograms = await (_db.select(_db.programs)
          ..where((t) => t.isBuiltIn.equals(false)))
        .get();
    final programIds = customPrograms.map((p) => p.id).toList();
    final days = programIds.isEmpty
        ? <ProgramDay>[]
        : await (_db.select(_db.programDays)
              ..where((t) => t.programId.isIn(programIds)))
            .get();
    final dayIds = days.map((d) => d.id).toList();
    final prescriptions = dayIds.isEmpty
        ? <Prescription>[]
        : await (_db.select(_db.prescriptions)
              ..where((t) => t.programDayId.isIn(dayIds)))
            .get();
    final prescriptionIds = prescriptions.map((p) => p.id).toList();
    final setGroups = prescriptionIds.isEmpty
        ? <SetGroup>[]
        : await (_db.select(_db.setGroups)
              ..where((t) => t.prescriptionId.isIn(prescriptionIds)))
            .get();

    final liftProgress = await _db.select(_db.liftProgressEntries).get();
    final sessions = await _db.select(_db.workoutSessions).get();
    final setLogs = await _db.select(_db.setLogs).get();
    final bodyweight = await _db.select(_db.bodyweightEntries).get();

    final backup = <String, dynamic>{
      'header': {
        'exportVersion': backupExportVersion,
        'schemaVersion': _db.schemaVersion,
        'appVersion': backupAppVersion,
        'exportedAt': DateTime.now().millisecondsSinceEpoch,
      },
      'settings': settings == null ? null : encodeSettings(settings),
      'exercises': customExercises.map(encodeExercise).toList(),
      'exerciseMuscles': muscles.map(encodeExerciseMuscle).toList(),
      'programs': customPrograms.map(encodeProgram).toList(),
      'programDays': days.map(encodeProgramDay).toList(),
      'prescriptions': prescriptions.map(encodePrescription).toList(),
      'setGroups': setGroups.map(encodeSetGroup).toList(),
      'liftProgress': liftProgress.map(encodeLiftProgress).toList(),
      'workoutSessions': sessions.map(encodeSession).toList(),
      'setLogs': setLogs.map(encodeSetLog).toList(),
      'bodyweightEntries': bodyweight.map(encodeBodyweight).toList(),
    };
    return jsonEncode(backup);
  }

  @override
  void validate(String json) => _validateHeader(_parse(json));

  @override
  Future<void> restoreFromJson(
    String json, {
    required String exercisesSeed,
    required String programsSeed,
  }) async {
    final root = _parse(json);
    _validateHeader(root);

    await _db.transaction(() async {
      await _wipe();
      await runSeed(
        _db,
        exercisesJson: exercisesSeed,
        programsJson: programsSeed,
      );
      try {
        await _import(root);
      } on CorruptBackupException {
        rethrow;
      } on Object catch (e) {
        // Any decode failure (bad enum, missing field, wrong type) aborts the
        // transaction so existing data is left untouched.
        throw CorruptBackupException('Backup could not be applied: $e');
      }
    });
  }

  // ---- helpers ----

  Map<String, dynamic> _parse(String json) {
    Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      throw const CorruptBackupException('File is not valid JSON.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const CorruptBackupException('Backup root is not an object.');
    }
    return decoded;
  }

  void _validateHeader(Map<String, dynamic> root) {
    final header = root['header'];
    if (header is! Map) {
      throw const CorruptBackupException('Backup is missing its header.');
    }
    final exportVersion = header['exportVersion'];
    if (exportVersion is! int) {
      throw const CorruptBackupException('Backup header is invalid.');
    }
    if (exportVersion > backupExportVersion) {
      throw IncompatibleBackupException(
        'This backup was made by a newer version of OpenLifts '
        '(format v$exportVersion). Update the app to restore it.',
      );
    }
    final schemaVersion = header['schemaVersion'];
    if (schemaVersion is int && schemaVersion > _db.schemaVersion) {
      throw IncompatibleBackupException(
        'This backup uses a newer data format (schema v$schemaVersion).',
      );
    }
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> root, String key) {
    final value = root[key];
    if (value == null) return const [];
    if (value is! List) {
      throw CorruptBackupException('"$key" is not a list.');
    }
    return value.cast<Map<String, dynamic>>();
  }

  Future<void> _wipe() async {
    await _db.delete(_db.setLogs).go();
    await _db.delete(_db.workoutSessions).go();
    await _db.delete(_db.bodyweightEntries).go();
    await _db.delete(_db.liftProgressEntries).go();
    await _db.delete(_db.setGroups).go();
    await _db.delete(_db.prescriptions).go();
    await _db.delete(_db.programDays).go();
    await _db.delete(_db.programs).go();
    await _db.delete(_db.exerciseMuscles).go();
    await _db.delete(_db.exercises).go();
    await _db.delete(_db.settings).go();
  }

  Future<void> _import(Map<String, dynamic> root) async {
    final settings = root['settings'];
    if (settings is Map<String, dynamic>) {
      await _db.into(_db.settings).insert(
            decodeSettings(settings, seed: currentSeedVersion),
            mode: InsertMode.insertOrReplace,
          );
    }

    for (final row in _rows(root, 'exercises')) {
      await _db.into(_db.exercises).insert(
            decodeExercise(row),
            mode: InsertMode.insertOrReplace,
          );
    }
    for (final row in _rows(root, 'exerciseMuscles')) {
      await _db.into(_db.exerciseMuscles).insert(
            decodeExerciseMuscle(row),
            mode: InsertMode.insertOrReplace,
          );
    }
    for (final row in _rows(root, 'programs')) {
      await _db.into(_db.programs).insert(
            decodeProgram(row),
            mode: InsertMode.insertOrReplace,
          );
    }
    for (final row in _rows(root, 'programDays')) {
      await _db.into(_db.programDays).insert(
            decodeProgramDay(row),
            mode: InsertMode.insertOrReplace,
          );
    }

    // Auto-increment ids are re-assigned and their foreign keys remapped.
    final prescriptionMap = <int, int>{};
    for (final row in _rows(root, 'prescriptions')) {
      final newId =
          await _db.into(_db.prescriptions).insert(decodePrescription(row));
      prescriptionMap[row['id'] as int] = newId;
    }
    for (final row in _rows(root, 'setGroups')) {
      final newPrescriptionId = prescriptionMap[row['prescriptionId'] as int];
      if (newPrescriptionId == null) {
        throw const CorruptBackupException(
          'A set group references a missing prescription.',
        );
      }
      await _db
          .into(_db.setGroups)
          .insert(decodeSetGroup(row, prescriptionId: newPrescriptionId));
    }

    for (final row in _rows(root, 'liftProgress')) {
      await _db.into(_db.liftProgressEntries).insert(
            decodeLiftProgress(row),
            mode: InsertMode.insertOrReplace,
          );
    }

    final sessionMap = <int, int>{};
    for (final row in _rows(root, 'workoutSessions')) {
      final newId =
          await _db.into(_db.workoutSessions).insert(decodeSession(row));
      sessionMap[row['id'] as int] = newId;
    }
    for (final row in _rows(root, 'setLogs')) {
      final newSessionId = sessionMap[row['sessionId'] as int];
      if (newSessionId == null) {
        throw const CorruptBackupException(
          'A logged set references a missing session.',
        );
      }
      await _db.into(_db.setLogs).insert(
            decodeSetLog(row, sessionId: newSessionId),
          );
    }

    for (final row in _rows(root, 'bodyweightEntries')) {
      await _db.into(_db.bodyweightEntries).insert(decodeBodyweight(row));
    }
  }
}
