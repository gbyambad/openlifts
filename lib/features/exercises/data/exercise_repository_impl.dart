import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/exercises/domain/exercise_repository.dart';

/// Drift-backed [ExerciseRepository].
class DriftExerciseRepository implements ExerciseRepository {
  DriftExerciseRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<List<Exercise>> watchAll() {
    final query = _db.select(_db.exercises)
      ..orderBy([(t) => OrderingTerm(expression: t.name)]);
    return query.watch();
  }

  @override
  Future<Exercise?> findById(String id) {
    final query = _db.select(_db.exercises)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }

  @override
  Future<Map<String, Exercise>> findByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final rows =
        await (_db.select(_db.exercises)..where((t) => t.id.isIn(ids))).get();
    return {for (final r in rows) r.id: r};
  }

  @override
  Future<List<Muscle>> primaryMusclesFor(String exerciseId) async {
    final query = _db.select(_db.exerciseMuscles)
      ..where(
        (t) => t.exerciseId.equals(exerciseId) & t.isPrimary.equals(true),
      );
    final rows = await query.get();
    return rows.map((r) => r.muscle).toList();
  }

  @override
  Future<List<Exercise>> byMuscle(Muscle muscle) {
    final query = _db.select(_db.exercises).join([
      innerJoin(
        _db.exerciseMuscles,
        _db.exerciseMuscles.exerciseId.equalsExp(_db.exercises.id),
      ),
    ])
      ..where(_db.exerciseMuscles.muscle.equalsValue(muscle));
    return query.map((row) => row.readTable(_db.exercises)).get();
  }
}
