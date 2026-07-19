import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/progression/domain/lift_progress_repository.dart';

/// Drift-backed [LiftProgressRepository].
class DriftLiftProgressRepository implements LiftProgressRepository {
  DriftLiftProgressRepository(this._db);

  final AppDatabase _db;

  @override
  Future<LiftProgress?> get(String exerciseId) {
    final query = _db.select(_db.liftProgressEntries)
      ..where((t) => t.exerciseId.equals(exerciseId));
    return query.getSingleOrNull();
  }

  @override
  Future<Map<String, LiftProgress>> getMany(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return {};
    final rows = await (_db.select(_db.liftProgressEntries)
          ..where((t) => t.exerciseId.isIn(exerciseIds)))
        .get();
    return {for (final r in rows) r.exerciseId: r};
  }

  @override
  Future<void> upsert({
    required String exerciseId,
    required double workingWeightKg,
    required DateTime updatedAt,
    int consecutiveFailures = 0,
  }) {
    return _db.into(_db.liftProgressEntries).insertOnConflictUpdate(
          LiftProgressEntriesCompanion.insert(
            exerciseId: exerciseId,
            workingWeightKg: workingWeightKg,
            updatedAt: updatedAt,
            consecutiveFailures: Value(consecutiveFailures),
          ),
        );
  }
}
