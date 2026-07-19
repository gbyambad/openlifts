import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/progression/data/lift_progress_repository_impl.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftLiftProgressRepository repo;

  setUp(() async {
    db = openTestDb();
    repo = DriftLiftProgressRepository(db);
    // FK: the exercise must exist first.
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'squat',
            name: 'Squat',
            equipment: Equipment.barbell,
            incrementKg: 2.5,
          ),
        );
  });
  tearDown(() => db.close());

  test('upsert then get round-trips, and updates in place', () async {
    await repo.upsert(
      exerciseId: 'squat',
      workingWeightKg: 60,
      updatedAt: DateTime(2026, 7, 18),
    );
    expect((await repo.get('squat'))?.workingWeightKg, 60);

    await repo.upsert(
      exerciseId: 'squat',
      workingWeightKg: 62.5,
      consecutiveFailures: 1,
      updatedAt: DateTime(2026, 7, 20),
    );
    final p = await repo.get('squat');
    expect(p?.workingWeightKg, 62.5);
    expect(p?.consecutiveFailures, 1);
    expect(await repo.get('nope'), isNull);
  });
}
