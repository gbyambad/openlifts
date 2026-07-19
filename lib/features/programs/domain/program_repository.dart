import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';

/// Input spec for building a program tree (used by the seed and by tests).
class NewProgram {
  const NewProgram({
    required this.id,
    required this.name,
    required this.progressionStyle,
    required this.scheduleMode,
    required this.days,
    this.description,
    this.isBuiltIn = false,
    this.structure,
    this.progressionPercent,
    this.timesPerWeek,
    this.everyNDays,
    this.weekdays,
    this.tags = const [],
  });

  final String id;
  final String name;
  final ProgressionStyle progressionStyle;
  final ScheduleMode scheduleMode;
  final List<NewDay> days;
  final String? description;
  final bool isBuiltIn;
  final String? structure;
  final double? progressionPercent;
  final int? timesPerWeek;
  final int? everyNDays;
  final List<int>? weekdays;
  final List<String> tags;
}

class NewDay {
  const NewDay({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.prescriptions,
  });

  final String id;
  final String name;
  final int orderIndex;
  final List<NewPrescription> prescriptions;
}

class NewPrescription {
  const NewPrescription({
    required this.exerciseId,
    required this.orderIndex,
    required this.setGroups,
    this.section = Section.main,
    this.optional = false,
  });

  final String exerciseId;
  final int orderIndex;
  final List<NewSetGroup> setGroups;
  final Section section;
  final bool optional;
}

class NewSetGroup {
  const NewSetGroup({
    required this.orderIndex,
    required this.sets,
    required this.reps,
    required this.weightRule,
    this.weightParam,
  });

  final int orderIndex;
  final int sets;
  final int reps;
  final WeightRule weightRule;
  final double? weightParam;
}

/// A fully-loaded program tree.
class ProgramTree {
  const ProgramTree({required this.program, required this.days});

  final Program program;
  final List<ProgramDayNode> days;
}

class ProgramDayNode {
  const ProgramDayNode({required this.day, required this.prescriptions});

  final ProgramDay day;
  final List<PrescriptionNode> prescriptions;
}

class PrescriptionNode {
  const PrescriptionNode({
    required this.prescription,
    required this.exercise,
    required this.setGroups,
  });

  final Prescription prescription;
  final Exercise exercise;
  final List<SetGroup> setGroups;
}

/// The program seam: built-in and custom programs go through one set of tables.
abstract interface class ProgramRepository {
  Future<List<Program>> all();

  /// The program row for [id], or null when none exists.
  Future<Program?> findById(String id);

  Future<void> insertProgram(NewProgram spec);

  Future<ProgramTree?> loadTree(String programId);

  /// Deep-copies a program into a new `isBuiltIn = false` program the user
  /// owns; the original is untouched (copy-on-edit).
  Future<String> copyAsCustom(
    String programId, {
    required String newId,
    required String newName,
  });

  /// Updates a program's schedule fields.
  Future<void> setSchedule(
    String programId, {
    required ScheduleMode mode,
    int? timesPerWeek,
    int? everyNDays,
    List<int>? weekdays,
  });

  /// Replaces the set-groups of [exerciseId] everywhere it appears in the
  /// program. Built-ins fork into a custom copy; returns the edited program's
  /// id (the fork's id when forked).
  Future<String> setExerciseScheme(
    String programId,
    String exerciseId,
    List<NewSetGroup> setGroups,
  );

  /// Deletes a program and its whole tree (days, prescriptions, set-groups).
  Future<void> deleteProgram(String programId);
}
