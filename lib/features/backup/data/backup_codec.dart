import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';

/// Pure row <-> JSON-map conversions for the backup format. Enums serialize by
/// name and dates as epoch milliseconds, so the file stays readable and stable
/// across enum reordering and storage changes.
///
/// Decoders return companions that OMIT auto-increment ids (the restore
/// re-assigns them and remaps foreign keys), so a backup never carries a raw id
/// into a table where it could collide with re-seeded built-ins.

// ---- typed map readers (throw on the wrong shape; caught as corruption) ----

String _s(Map<String, dynamic> m, String k) => m[k] as String;
String? _sn(Map<String, dynamic> m, String k) => m[k] as String?;
int _i(Map<String, dynamic> m, String k) => m[k] as int;
int? _in(Map<String, dynamic> m, String k) => m[k] as int?;
double _d(Map<String, dynamic> m, String k) => (m[k] as num).toDouble();
double? _dn(Map<String, dynamic> m, String k) => (m[k] as num?)?.toDouble();
bool _b(Map<String, dynamic> m, String k) => m[k] as bool;
DateTime _date(Map<String, dynamic> m, String k) =>
    DateTime.fromMillisecondsSinceEpoch(m[k] as int);
DateTime? _dateN(Map<String, dynamic> m, String k) =>
    m[k] == null ? null : DateTime.fromMillisecondsSinceEpoch(m[k] as int);
int _epoch(DateTime d) => d.millisecondsSinceEpoch;

// ---- Exercise ----

Map<String, dynamic> encodeExercise(Exercise e) => {
      'id': e.id,
      'name': e.name,
      'movementPattern': e.movementPattern?.name,
      'equipment': e.equipment.name,
      'mechanic': e.mechanic?.name,
      'incrementKg': e.incrementKg,
      'incrementEverySessions': e.incrementEverySessions,
      'deloadAfterFails': e.deloadAfterFails,
      'deloadPercent': e.deloadPercent,
      'restSecondsOverride': e.restSecondsOverride,
      'startsLoaded': e.startsLoaded,
      'variationOf': e.variationOf,
      'isCustom': e.isCustom,
      'instructions': e.instructions,
      'imagePaths': e.imagePaths,
    };

ExercisesCompanion decodeExercise(Map<String, dynamic> m) => ExercisesCompanion(
      id: Value(_s(m, 'id')),
      name: Value(_s(m, 'name')),
      movementPattern: Value(
        m['movementPattern'] == null
            ? null
            : MovementPattern.values.byName(_s(m, 'movementPattern')),
      ),
      equipment: Value(Equipment.values.byName(_s(m, 'equipment'))),
      mechanic: Value(
        m['mechanic'] == null
            ? null
            : Mechanic.values.byName(_s(m, 'mechanic')),
      ),
      incrementKg: Value(_d(m, 'incrementKg')),
      incrementEverySessions: Value(_i(m, 'incrementEverySessions')),
      deloadAfterFails: Value(_i(m, 'deloadAfterFails')),
      deloadPercent: Value(_d(m, 'deloadPercent')),
      restSecondsOverride: Value(_in(m, 'restSecondsOverride')),
      startsLoaded: Value(_b(m, 'startsLoaded')),
      variationOf: Value(_sn(m, 'variationOf')),
      isCustom: Value(_b(m, 'isCustom')),
      instructions: Value((m['instructions'] as List).cast<String>()),
      imagePaths: Value((m['imagePaths'] as List).cast<String>()),
    );

// ---- ExerciseMuscle ----

Map<String, dynamic> encodeExerciseMuscle(ExerciseMuscle m) => {
      'exerciseId': m.exerciseId,
      'muscle': m.muscle.name,
      'isPrimary': m.isPrimary,
    };

ExerciseMusclesCompanion decodeExerciseMuscle(Map<String, dynamic> m) =>
    ExerciseMusclesCompanion.insert(
      exerciseId: _s(m, 'exerciseId'),
      muscle: Muscle.values.byName(_s(m, 'muscle')),
      isPrimary: Value(_b(m, 'isPrimary')),
    );

// ---- Program ----

Map<String, dynamic> encodeProgram(Program p) => {
      'id': p.id,
      'name': p.name,
      'description': p.description,
      'isBuiltIn': p.isBuiltIn,
      'structure': p.structure,
      'progressionStyle': p.progressionStyle.name,
      'progressionPercent': p.progressionPercent,
      'scheduleMode': p.scheduleMode.name,
      'timesPerWeek': p.timesPerWeek,
      'everyNDays': p.everyNDays,
      'weekdays': p.weekdays,
      'tags': p.tags,
    };

ProgramsCompanion decodeProgram(Map<String, dynamic> m) => ProgramsCompanion(
      id: Value(_s(m, 'id')),
      name: Value(_s(m, 'name')),
      description: Value(_sn(m, 'description')),
      isBuiltIn: Value(_b(m, 'isBuiltIn')),
      structure: Value(_sn(m, 'structure')),
      progressionStyle:
          Value(ProgressionStyle.values.byName(_s(m, 'progressionStyle'))),
      progressionPercent: Value(_dn(m, 'progressionPercent')),
      scheduleMode: Value(ScheduleMode.values.byName(_s(m, 'scheduleMode'))),
      timesPerWeek: Value(_in(m, 'timesPerWeek')),
      everyNDays: Value(_in(m, 'everyNDays')),
      weekdays: Value((m['weekdays'] as List?)?.cast<int>()),
      tags: Value((m['tags'] as List?)?.cast<String>() ?? const []),
    );

// ---- ProgramDay ----

Map<String, dynamic> encodeProgramDay(ProgramDay d) => {
      'id': d.id,
      'programId': d.programId,
      'name': d.name,
      'orderIndex': d.orderIndex,
    };

ProgramDaysCompanion decodeProgramDay(Map<String, dynamic> m) =>
    ProgramDaysCompanion.insert(
      id: _s(m, 'id'),
      programId: _s(m, 'programId'),
      name: _s(m, 'name'),
      orderIndex: _i(m, 'orderIndex'),
    );

// ---- Prescription (auto-inc id omitted; caller keeps map['id'] to remap) ----

Map<String, dynamic> encodePrescription(Prescription p) => {
      'id': p.id,
      'programDayId': p.programDayId,
      'exerciseId': p.exerciseId,
      'orderIndex': p.orderIndex,
      'section': p.section.name,
      'optional': p.optional,
    };

PrescriptionsCompanion decodePrescription(Map<String, dynamic> m) =>
    PrescriptionsCompanion.insert(
      programDayId: _s(m, 'programDayId'),
      exerciseId: _s(m, 'exerciseId'),
      orderIndex: _i(m, 'orderIndex'),
      section: Section.values.byName(_s(m, 'section')),
      optional: Value(_b(m, 'optional')),
    );

// ---- SetGroup (prescriptionId supplied remapped) ----

Map<String, dynamic> encodeSetGroup(SetGroup g) => {
      'id': g.id,
      'prescriptionId': g.prescriptionId,
      'orderIndex': g.orderIndex,
      'sets': g.sets,
      'reps': g.reps,
      'weightRule': g.weightRule.name,
      'weightParam': g.weightParam,
    };

SetGroupsCompanion decodeSetGroup(
  Map<String, dynamic> m, {
  required int prescriptionId,
}) =>
    SetGroupsCompanion.insert(
      prescriptionId: prescriptionId,
      orderIndex: _i(m, 'orderIndex'),
      sets: _i(m, 'sets'),
      reps: _i(m, 'reps'),
      weightRule: WeightRule.values.byName(_s(m, 'weightRule')),
      weightParam: Value(_dn(m, 'weightParam')),
    );

// ---- LiftProgress ----

Map<String, dynamic> encodeLiftProgress(LiftProgress p) => {
      'exerciseId': p.exerciseId,
      'workingWeightKg': p.workingWeightKg,
      'consecutiveFailures': p.consecutiveFailures,
      'updatedAt': _epoch(p.updatedAt),
    };

LiftProgressEntriesCompanion decodeLiftProgress(Map<String, dynamic> m) =>
    LiftProgressEntriesCompanion.insert(
      exerciseId: _s(m, 'exerciseId'),
      workingWeightKg: _d(m, 'workingWeightKg'),
      consecutiveFailures: Value(_i(m, 'consecutiveFailures')),
      updatedAt: _date(m, 'updatedAt'),
    );

// ---- WorkoutSession (auto-inc id omitted; caller keeps map['id'] to remap) --

Map<String, dynamic> encodeSession(WorkoutSession s) => {
      'id': s.id,
      'programDayId': s.programDayId,
      'startedAt': _epoch(s.startedAt),
      'completedAt': s.completedAt == null ? null : _epoch(s.completedAt!),
    };

WorkoutSessionsCompanion decodeSession(Map<String, dynamic> m) =>
    WorkoutSessionsCompanion.insert(
      programDayId: _s(m, 'programDayId'),
      startedAt: _date(m, 'startedAt'),
      completedAt: Value(_dateN(m, 'completedAt')),
    );

// ---- SetLog (sessionId supplied remapped) ----

Map<String, dynamic> encodeSetLog(SetLog l) => {
      'id': l.id,
      'sessionId': l.sessionId,
      'exerciseId': l.exerciseId,
      'setIndex': l.setIndex,
      'weightKg': l.weightKg,
      'targetReps': l.targetReps,
      'actualReps': l.actualReps,
    };

SetLogsCompanion decodeSetLog(
  Map<String, dynamic> m, {
  required int sessionId,
}) =>
    SetLogsCompanion.insert(
      sessionId: sessionId,
      exerciseId: _s(m, 'exerciseId'),
      setIndex: _i(m, 'setIndex'),
      weightKg: _d(m, 'weightKg'),
      targetReps: _i(m, 'targetReps'),
      actualReps: Value(_in(m, 'actualReps')),
    );

// ---- BodyweightEntry (auto-inc id dropped; nothing references it) ----

Map<String, dynamic> encodeBodyweight(BodyweightEntry e) => {
      'loggedAt': _epoch(e.loggedAt),
      'weightKg': e.weightKg,
      'note': e.note,
    };

BodyweightEntriesCompanion decodeBodyweight(Map<String, dynamic> m) =>
    BodyweightEntriesCompanion.insert(
      loggedAt: _date(m, 'loggedAt'),
      weightKg: _d(m, 'weightKg'),
      note: Value(_sn(m, 'note')),
    );

// ---- Settings (single row; seedVersion is set by the restore, not here) ----

Map<String, dynamic> encodeSettings(Setting s) => {
      'unit': s.unit.name,
      'barWeightKg': s.barWeightKg,
      'restTimerSeconds': s.restTimerSeconds,
      'activeProgramId': s.activeProgramId,
      'themeMode': s.themeMode.name,
    };

SettingsCompanion decodeSettings(Map<String, dynamic> m, {required int seed}) =>
    SettingsCompanion.insert(
      id: const Value(1),
      unit: Unit.values.byName(_s(m, 'unit')),
      barWeightKg: _d(m, 'barWeightKg'),
      restTimerSeconds: _i(m, 'restTimerSeconds'),
      activeProgramId: Value(_sn(m, 'activeProgramId')),
      seedVersion: Value(seed),
      // Older backups predate the theme setting; fall back to the default.
      themeMode: Value(
        m['themeMode'] == null
            ? ThemeMode.dark
            : ThemeMode.values.byName(_s(m, 'themeMode')),
      ),
    );
