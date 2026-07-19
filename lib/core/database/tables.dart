import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:openlifts/core/database/converters.dart';

/// Movement-pattern taxonomy (nullable on the catalog — curated for programmed
/// lifts, left null for the long tail).
enum MovementPattern {
  horizontalPush,
  horizontalPull,
  verticalPush,
  verticalPull,
  squat,
  hinge,
}

enum Equipment { barbell, dumbbell, bodyweight, machine, cable, other }

enum Mechanic { compound, isolation }

enum Muscle {
  chest,
  upperBack,
  lats,
  shoulders,
  quads,
  hamstrings,
  glutes,
  lowerBack,
  biceps,
  triceps,
  core,
  calves,
  forearms,
  traps,
}

enum Unit { kg, lb }

/// How a set-group's per-set weights derive from the lift's anchor weight.
enum WeightRule { straight, ramp, topSet, backoff, percentOfAnchor }

enum ProgressionStyle { linear, percentage }

enum ScheduleMode { timesPerWeek, everyNDays, fixedWeekdays }

enum Section { main, accessory }

/// The exercise catalog: intrinsic properties + per-exercise (global)
/// progression config. Volume (sets/reps) lives on prescriptions, not here.
class Exercises extends Table {
  TextColumn get id => text()(); // slug PK, e.g. 'squat'
  TextColumn get name => text()();

  TextColumn get movementPattern => textEnum<MovementPattern>().nullable()();
  TextColumn get equipment => textEnum<Equipment>()();
  TextColumn get mechanic => textEnum<Mechanic>().nullable()();

  // Progression config (per-exercise, global).
  RealColumn get incrementKg => real()();
  IntColumn get incrementEverySessions =>
      integer().withDefault(const Constant(1))();
  IntColumn get deloadAfterFails => integer().withDefault(const Constant(3))();
  RealColumn get deloadPercent => real().withDefault(const Constant(10))();

  IntColumn get restSecondsOverride => integer().nullable()();
  BoolColumn get startsLoaded => boolean().withDefault(const Constant(false))();
  TextColumn get variationOf => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  TextColumn get instructions => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();
  TextColumn get imagePaths => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Queryable muscle tagging (join) — StrongLifts recommends/filters by muscle.
class ExerciseMuscles extends Table {
  TextColumn get exerciseId => text().references(Exercises, #id)();
  TextColumn get muscle => textEnum<Muscle>()();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {exerciseId, muscle};
}

/// Per-exercise progression state (global; the shared anchor for both
/// linear and percentage styles).
@DataClassName('LiftProgress')
class LiftProgressEntries extends Table {
  TextColumn get exerciseId => text().references(Exercises, #id)();
  RealColumn get workingWeightKg => real()();
  IntColumn get consecutiveFailures =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {exerciseId};
}

/// A training program (built-in or custom) — the root of the program tree.
class Programs extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();
  TextColumn get structure => text().nullable()();
  TextColumn get progressionStyle => textEnum<ProgressionStyle>()();
  RealColumn get progressionPercent => real().nullable()();
  TextColumn get scheduleMode => textEnum<ScheduleMode>()();
  IntColumn get timesPerWeek => integer().nullable()();
  IntColumn get everyNDays => integer().nullable()();
  TextColumn get weekdays => text().map(const IntListConverter()).nullable()();
  // Category chips shown on the program list (e.g. "Beginner", "Strength").
  TextColumn get tags => text()
      .map(const StringListConverter())
      .withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// A workout within a program (Workout A/B/C, or Upper/Lower days).
class ProgramDays extends Table {
  TextColumn get id => text()();
  TextColumn get programId => text().references(Programs, #id)();
  TextColumn get name => text()();
  IntColumn get orderIndex => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// An exercise's slot within a program day (ProgramDay x Exercise).
class Prescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programDayId => text().references(ProgramDays, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get orderIndex => integer()();
  TextColumn get section => textEnum<Section>()();
  BoolColumn get optional => boolean().withDefault(const Constant(false))();
}

/// One block of sets within a prescription (ordered).
class SetGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prescriptionId => integer().references(Prescriptions, #id)();
  IntColumn get orderIndex => integer()();
  IntColumn get sets => integer()();
  IntColumn get reps => integer()();
  TextColumn get weightRule => textEnum<WeightRule>()();
  RealColumn get weightParam => real().nullable()();
}

/// One performed (or in-progress) workout.
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get programDayId => text().references(ProgramDays, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt =>
      dateTime().nullable()(); // null = in progress
}

/// A logged working set (per-set weight supports top/back-off natively).
class SetLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().references(WorkoutSessions, #id)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  RealColumn get weightKg => real()();
  IntColumn get targetReps => integer()();
  IntColumn get actualReps => integer().nullable()(); // null until logged
}

/// The user's bodyweight over time (standalone time-series).
class BodyweightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
}

/// Single-row app preferences (fixed `id = 1`).
class Settings extends Table {
  IntColumn get id => integer()();
  TextColumn get unit => textEnum<Unit>()();
  RealColumn get barWeightKg => real()();
  IntColumn get restTimerSeconds => integer()();
  TextColumn get activeProgramId => text().nullable()();
  IntColumn get seedVersion => integer().withDefault(const Constant(0))();
  // Stored as the ThemeMode enum name; defaults to the brand's dark ground.
  TextColumn get themeMode =>
      textEnum<ThemeMode>().withDefault(const Constant('dark'))();

  // When the user last acted on a welcome-back deload prompt (applied or
  // dismissed) — so the same layoff isn't prompted twice.
  DateTimeColumn get deloadHandledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
