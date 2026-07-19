import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/data/program_repository_impl.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';

import '../../support/test_database.dart';

NewProgram _sampleProgram({
  required String id,
  bool isBuiltIn = true,
}) {
  return NewProgram(
    id: id,
    name: 'StrongLifts 5x5',
    isBuiltIn: isBuiltIn,
    progressionStyle: ProgressionStyle.linear,
    scheduleMode: ScheduleMode.timesPerWeek,
    timesPerWeek: 3,
    days: const [
      NewDay(
        id: 'a',
        name: 'Workout A',
        orderIndex: 0,
        prescriptions: [
          NewPrescription(
            exerciseId: 'squat',
            orderIndex: 0,
            setGroups: [
              NewSetGroup(
                orderIndex: 0,
                sets: 5,
                reps: 5,
                weightRule: WeightRule.straight,
              ),
            ],
          ),
        ],
      ),
      NewDay(
        id: 'b',
        name: 'Workout B',
        orderIndex: 1,
        prescriptions: [
          NewPrescription(
            exerciseId: 'deadlift',
            orderIndex: 0,
            setGroups: [
              NewSetGroup(
                orderIndex: 0,
                sets: 1,
                reps: 5,
                weightRule: WeightRule.straight,
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  late AppDatabase db;
  late DriftProgramRepository repo;

  setUp(() async {
    db = openTestDb();
    repo = DriftProgramRepository(db);
    for (final id in ['squat', 'deadlift']) {
      await db.into(db.exercises).insert(
            ExercisesCompanion.insert(
              id: id,
              name: id,
              equipment: Equipment.barbell,
              incrementKg: 2.5,
            ),
          );
    }
  });
  tearDown(() => db.close());

  test('a program tree reads back with ordered days and set groups', () async {
    await repo.insertProgram(_sampleProgram(id: 'sl5x5'));
    final tree = await repo.loadTree('sl5x5');

    expect(tree, isNotNull);
    expect(tree!.program.timesPerWeek, 3);
    expect(tree.days.map((d) => d.day.name), ['Workout A', 'Workout B']);
    final squat = tree.days.first.prescriptions.single;
    expect(squat.exercise.id, 'squat');
    expect(squat.setGroups.single.sets, 5);
  });

  test('editing a built-in forks a custom copy; original intact', () async {
    await repo.insertProgram(_sampleProgram(id: 'sl5x5'));
    final newId = await repo.copyAsCustom(
      'sl5x5',
      newId: 'my5x5',
      newName: 'My 5x5',
    );

    final copy = await repo.loadTree(newId);
    final original = await repo.loadTree('sl5x5');
    expect(copy!.program.isBuiltIn, isFalse);
    expect(copy.program.name, 'My 5x5');
    expect(copy.days.length, 2);
    expect(original!.program.isBuiltIn, isTrue); // untouched
  });

  test('custom program reads through the same queries as a built-in', () async {
    await repo.insertProgram(_sampleProgram(id: 'custom', isBuiltIn: false));
    final tree = await repo.loadTree('custom');
    expect(tree!.program.isBuiltIn, isFalse);
    expect(tree.days.length, 2);
  });

  test('setExerciseScheme forks a built-in and replaces the exercise groups',
      () async {
    await repo.insertProgram(_sampleProgram(id: 'sl5x5'));

    final targetId = await repo.setExerciseScheme(
      'sl5x5',
      'squat',
      buildSetGroups(SetSchemeType.topBackoff, 5, 3),
    );
    expect(targetId, 'sl5x5-custom');

    final custom = await repo.loadTree(targetId);
    final squat = custom!.days.first.prescriptions
        .firstWhere((p) => p.exercise.id == 'squat');
    // Top set + back-off => 2 groups, 5 sets total, 3 reps.
    expect(squat.setGroups.length, 2);
    expect(squat.setGroups.fold<int>(0, (s, g) => s + g.sets), 5);
    expect(squat.setGroups.first.reps, 3);
    expect(
      squat.setGroups.map((g) => g.weightRule),
      containsAll([WeightRule.topSet, WeightRule.backoff]),
    );

    // The built-in original is untouched.
    final original = await repo.loadTree('sl5x5');
    expect(
      original!.days.first.prescriptions.single.setGroups.single.weightRule,
      WeightRule.straight,
    );
  });
}
