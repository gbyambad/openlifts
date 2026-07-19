import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';

/// Drift-backed [ProgramRepository].
class DriftProgramRepository implements ProgramRepository {
  DriftProgramRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Program>> all() => _db.select(_db.programs).get();

  @override
  Future<Program?> findById(String id) =>
      (_db.select(_db.programs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Deletes a program's whole tree (set-groups → prescriptions → days) in FK
  /// order, leaving the `programs` row itself untouched. Must run inside a
  /// transaction. No-op when the program has no days.
  Future<void> _deleteTree(String programId) async {
    final dayIds = await (_db.selectOnly(_db.programDays)
          ..addColumns([_db.programDays.id])
          ..where(_db.programDays.programId.equals(programId)))
        .map((r) => r.read(_db.programDays.id)!)
        .get();
    if (dayIds.isEmpty) return;
    final presIds = await (_db.selectOnly(_db.prescriptions)
          ..addColumns([_db.prescriptions.id])
          ..where(_db.prescriptions.programDayId.isIn(dayIds)))
        .map((r) => r.read(_db.prescriptions.id)!)
        .get();
    if (presIds.isNotEmpty) {
      await (_db.delete(_db.setGroups)
            ..where((t) => t.prescriptionId.isIn(presIds)))
          .go();
    }
    await (_db.delete(_db.prescriptions)
          ..where((t) => t.programDayId.isIn(dayIds)))
        .go();
    await (_db.delete(_db.programDays)
          ..where((t) => t.programId.equals(programId)))
        .go();
  }

  @override
  Future<void> insertProgram(NewProgram s) => _db.transaction(() async {
        // Idempotent replace: clear any existing tree for this id first, so
        // re-seeding or re-forking (fixed `-custom` id) never accumulates
        // duplicate prescriptions/set-groups.
        await _deleteTree(s.id);

        await _db.into(_db.programs).insert(
              ProgramsCompanion.insert(
                id: s.id,
                name: s.name,
                progressionStyle: s.progressionStyle,
                scheduleMode: s.scheduleMode,
                description: Value(s.description),
                isBuiltIn: Value(s.isBuiltIn),
                structure: Value(s.structure),
                progressionPercent: Value(s.progressionPercent),
                timesPerWeek: Value(s.timesPerWeek),
                everyNDays: Value(s.everyNDays),
                weekdays: Value(s.weekdays),
                tags: Value(s.tags),
              ),
              mode: InsertMode.insertOrReplace,
            );
        for (final d in s.days) {
          await _db.into(_db.programDays).insert(
                ProgramDaysCompanion.insert(
                  id: d.id,
                  programId: s.id,
                  name: d.name,
                  orderIndex: d.orderIndex,
                ),
                mode: InsertMode.insertOrReplace,
              );
          for (final p in d.prescriptions) {
            final prescriptionId = await _db.into(_db.prescriptions).insert(
                  PrescriptionsCompanion.insert(
                    programDayId: d.id,
                    exerciseId: p.exerciseId,
                    orderIndex: p.orderIndex,
                    section: p.section,
                    optional: Value(p.optional),
                  ),
                );
            for (final g in p.setGroups) {
              await _db.into(_db.setGroups).insert(
                    SetGroupsCompanion.insert(
                      prescriptionId: prescriptionId,
                      orderIndex: g.orderIndex,
                      sets: g.sets,
                      reps: g.reps,
                      weightRule: g.weightRule,
                      weightParam: Value(g.weightParam),
                    ),
                  );
            }
          }
        }
      });

  @override
  Future<ProgramTree?> loadTree(String programId) async {
    final program = await (_db.select(_db.programs)
          ..where((t) => t.id.equals(programId)))
        .getSingleOrNull();
    if (program == null) return null;

    final days = await (_db.select(_db.programDays)
          ..where((t) => t.programId.equals(programId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();
    if (days.isEmpty) return ProgramTree(program: program, days: const []);

    // Load the whole tree in three batched queries (one per level) instead of a
    // query per day and per prescription, then assemble in Dart. A global
    // orderBy orderIndex keeps each day's/prescription's children in order once
    // bucketed.
    final dayIds = [for (final d in days) d.id];
    final prescriptions = await (_db.select(_db.prescriptions)
          ..where((t) => t.programDayId.isIn(dayIds))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
        .get();

    final presIds = [for (final p in prescriptions) p.id];
    final groups = presIds.isEmpty
        ? <SetGroup>[]
        : await (_db.select(_db.setGroups)
              ..where((t) => t.prescriptionId.isIn(presIds))
              ..orderBy([(t) => OrderingTerm(expression: t.orderIndex)]))
            .get();

    final exerciseIds = {for (final p in prescriptions) p.exerciseId}.toList();
    final exercises = exerciseIds.isEmpty
        ? <Exercise>[]
        : await (_db.select(_db.exercises)
              ..where((t) => t.id.isIn(exerciseIds)))
            .get();
    final exerciseById = {for (final e in exercises) e.id: e};

    final presByDay = <String, List<Prescription>>{};
    for (final p in prescriptions) {
      presByDay.putIfAbsent(p.programDayId, () => []).add(p);
    }
    final groupsByPres = <int, List<SetGroup>>{};
    for (final g in groups) {
      groupsByPres.putIfAbsent(g.prescriptionId, () => []).add(g);
    }

    final dayNodes = [
      for (final day in days)
        ProgramDayNode(
          day: day,
          prescriptions: [
            for (final p in presByDay[day.id] ?? const <Prescription>[])
              PrescriptionNode(
                prescription: p,
                exercise: exerciseById[p.exerciseId]!,
                setGroups: groupsByPres[p.id] ?? const [],
              ),
          ],
        ),
    ];
    return ProgramTree(program: program, days: dayNodes);
  }

  /// Rebuilds a [NewProgram] spec from a loaded [tree]. Callers supply only the
  /// bits that differ: the program [id]/[name], each day's id ([dayId]), and
  /// optionally per-prescription set-groups ([overrideSetGroups] — return null
  /// to keep the existing ones).
  NewProgram _specFromTree(
    ProgramTree tree, {
    required String id,
    required String name,
    required String Function(ProgramDayNode day) dayId,
    List<NewSetGroup>? Function(PrescriptionNode prescription)?
        overrideSetGroups,
  }) {
    final p = tree.program;
    return NewProgram(
      id: id,
      name: name,
      progressionStyle: p.progressionStyle,
      scheduleMode: p.scheduleMode,
      description: p.description,
      structure: p.structure,
      progressionPercent: p.progressionPercent,
      timesPerWeek: p.timesPerWeek,
      everyNDays: p.everyNDays,
      weekdays: p.weekdays,
      tags: p.tags,
      days: [
        for (final dn in tree.days)
          NewDay(
            id: dayId(dn),
            name: dn.day.name,
            orderIndex: dn.day.orderIndex,
            prescriptions: [
              for (final pn in dn.prescriptions)
                NewPrescription(
                  exerciseId: pn.exercise.id,
                  orderIndex: pn.prescription.orderIndex,
                  section: pn.prescription.section,
                  optional: pn.prescription.optional,
                  setGroups: overrideSetGroups?.call(pn) ??
                      [
                        for (final g in pn.setGroups)
                          NewSetGroup(
                            orderIndex: g.orderIndex,
                            sets: g.sets,
                            reps: g.reps,
                            weightRule: g.weightRule,
                            weightParam: g.weightParam,
                          ),
                      ],
                ),
            ],
          ),
      ],
    );
  }

  @override
  Future<String> copyAsCustom(
    String programId, {
    required String newId,
    required String newName,
  }) async {
    final tree = await loadTree(programId);
    if (tree == null) {
      throw ArgumentError('No program with id $programId');
    }
    await insertProgram(
      _specFromTree(
        tree,
        id: newId,
        name: newName,
        dayId: (dn) => '$newId-${dn.day.orderIndex}',
      ),
    );
    return newId;
  }

  @override
  Future<void> setSchedule(
    String programId, {
    required ScheduleMode mode,
    int? timesPerWeek,
    int? everyNDays,
    List<int>? weekdays,
  }) {
    return (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
        .write(
      ProgramsCompanion(
        scheduleMode: Value(mode),
        timesPerWeek: Value(timesPerWeek),
        everyNDays: Value(everyNDays),
        weekdays: Value(weekdays),
      ),
    );
  }

  @override
  Future<String> setExerciseScheme(
    String programId,
    String exerciseId,
    List<NewSetGroup> setGroups,
  ) async {
    final tree = await loadTree(programId);
    if (tree == null) throw ArgumentError('No program with id $programId');
    final p = tree.program;
    final fork = p.isBuiltIn;
    final targetId = fork ? '$programId-custom' : programId;

    await insertProgram(
      _specFromTree(
        tree,
        id: targetId,
        name: fork ? '${p.name} (Custom)' : p.name,
        dayId: (dn) => fork ? '$targetId-${dn.day.orderIndex}' : dn.day.id,
        overrideSetGroups: (pn) =>
            pn.exercise.id == exerciseId ? setGroups : null,
      ),
    );
    return targetId;
  }

  @override
  Future<void> deleteProgram(String programId) => _db.transaction(() async {
        await _deleteTree(programId);
        await (_db.delete(_db.programs)..where((t) => t.id.equals(programId)))
            .go();
      });
}
