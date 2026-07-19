import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/bodyweight/domain/bodyweight_repository.dart';

/// Drift-backed [BodyweightRepository].
class DriftBodyweightRepository implements BodyweightRepository {
  DriftBodyweightRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> add(DateTime loggedAt, double weightKg, {String? note}) {
    return _db.into(_db.bodyweightEntries).insert(
          BodyweightEntriesCompanion.insert(
            loggedAt: loggedAt,
            weightKg: weightKg,
            note: Value(note),
          ),
        );
  }

  @override
  Future<List<BodyweightEntry>> series() {
    return (_db.select(_db.bodyweightEntries)
          ..orderBy([(t) => OrderingTerm(expression: t.loggedAt)]))
        .get();
  }

  @override
  Stream<List<BodyweightEntry>> watchSeries() {
    return (_db.select(_db.bodyweightEntries)
          ..orderBy([(t) => OrderingTerm(expression: t.loggedAt)]))
        .watch();
  }
}
