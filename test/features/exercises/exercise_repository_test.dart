import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/exercises/data/exercise_repository_impl.dart';
import 'package:openlifts/features/exercises/data/exercise_seed.dart';

import '../../support/test_database.dart';

const _fixture = '''
[
  {"id":"squat","name":"Squat","equipment":"barbell","movementPattern":"squat","incrementKg":2.5,"instructions":["Brace and squat below parallel."],"muscles":[{"name":"quads","primary":true},{"name":"glutes","primary":true},{"name":"hamstrings","primary":false}]},
  {"id":"bench_press","name":"Bench Press","equipment":"barbell","movementPattern":"horizontalPush","incrementKg":2.5},
  {"id":"barbell_row","name":"Barbell Row","equipment":"barbell","movementPattern":"horizontalPull","incrementKg":2.5,"startsLoaded":true},
  {"id":"overhead_press","name":"Overhead Press","equipment":"barbell","movementPattern":"verticalPush","incrementKg":2.5},
  {"id":"deadlift","name":"Deadlift","equipment":"barbell","movementPattern":"hinge","incrementKg":5.0,"startsLoaded":true}
]
''';

void main() {
  late AppDatabase db;
  late DriftExerciseRepository repo;

  setUp(() {
    db = openTestDb();
    repo = DriftExerciseRepository(db);
  });
  tearDown(() => db.close());

  test('seeds five lifts and streams them ordered by name', () async {
    await seedExercisesFromJson(db, _fixture);
    final rows = await repo.watchAll().first;
    expect(rows.length, 5);
    expect(rows.map((e) => e.name).toList(), [
      'Barbell Row',
      'Bench Press',
      'Deadlift',
      'Overhead Press',
      'Squat',
    ]);
  });

  test('watchAll re-emits when a new exercise is inserted', () async {
    final counts = <int>[];
    final sub = repo.watchAll().listen((rows) => counts.add(rows.length));
    await pumpEventQueue();

    await seedExercisesFromJson(db, _fixture);
    await pumpEventQueue();

    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'dip',
            name: 'Dip',
            equipment: Equipment.bodyweight,
            incrementKg: 2.5,
          ),
        );
    await pumpEventQueue();
    await sub.cancel();

    expect(counts, containsAllInOrder([0, 5, 6]));
  });

  test('seeding twice is idempotent', () async {
    await seedExercisesFromJson(db, _fixture);
    await seedExercisesFromJson(db, _fixture);
    final rows = await repo.watchAll().first;
    expect(rows.length, 5);
  });

  test('findById returns the row or null, instructions round-trip', () async {
    await seedExercisesFromJson(db, _fixture);
    final squat = await repo.findById('squat');
    expect(squat?.name, 'Squat');
    expect(squat?.instructions, isNotEmpty);
    expect(await repo.findById('nope'), isNull);
  });

  test('seeding attaches muscles and supports query-by-muscle', () async {
    await seedExercisesFromJson(db, _fixture);
    expect(await repo.primaryMusclesFor('squat'), contains(Muscle.quads));
    final quadLifts = await repo.byMuscle(Muscle.quads);
    expect(quadLifts.map((e) => e.id), contains('squat'));
  });
}
