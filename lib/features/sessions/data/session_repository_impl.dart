import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';

/// Drift-backed [SessionRepository].
class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository(this._db);

  final AppDatabase _db;

  @override
  Future<int> startSession(String programDayId, DateTime startedAt) {
    return _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            programDayId: programDayId,
            startedAt: startedAt,
          ),
        );
  }

  @override
  Future<void> logSet({
    required int sessionId,
    required String exerciseId,
    required int setIndex,
    required double weightKg,
    required int targetReps,
    int? actualReps,
  }) {
    return _db.into(_db.setLogs).insert(
          SetLogsCompanion.insert(
            sessionId: sessionId,
            exerciseId: exerciseId,
            setIndex: setIndex,
            weightKg: weightKg,
            targetReps: targetReps,
            actualReps: Value(actualReps),
          ),
        );
  }

  @override
  Future<void> completeSession(int sessionId, DateTime completedAt) {
    return (_db.update(_db.workoutSessions)
          ..where((t) => t.id.equals(sessionId)))
        .write(WorkoutSessionsCompanion(completedAt: Value(completedAt)));
  }

  @override
  Future<List<SetLog>> setsFor(int sessionId) {
    return (_db.select(_db.setLogs)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm(expression: t.setIndex)]))
        .get();
  }

  @override
  Stream<List<WorkoutSession>> watchRecent({int limit = 20}) {
    return (_db.select(_db.workoutSessions)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.startedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(limit))
        .watch();
  }

  @override
  Stream<List<LiftSeriesPoint>> watchLiftSeries() {
    final sessions = _db.workoutSessions;
    final logs = _db.setLogs;
    final query = _db.select(logs).join([
      innerJoin(sessions, sessions.id.equalsExp(logs.sessionId)),
    ])
      ..where(sessions.completedAt.isNotNull() & logs.actualReps.isNotNull())
      ..orderBy([OrderingTerm(expression: sessions.startedAt)]);
    return query.watch().map(
          (rows) => rows.map((row) {
            final log = row.readTable(logs);
            final session = row.readTable(sessions);
            return LiftSeriesPoint(
              exerciseId: log.exerciseId,
              date: session.startedAt,
              weightKg: log.weightKg,
            );
          }).toList(),
        );
  }

  @override
  Stream<List<HistoryEntry>> watchHistory() {
    final sessions = _db.workoutSessions;
    final days = _db.programDays;
    final logs = _db.setLogs;
    final setsLogged = logs.id.count();
    final topSet = logs.weightKg.max();
    final volume = (logs.weightKg * logs.actualReps.cast<double>()).sum();

    final query = _db.select(sessions).join([
      leftOuterJoin(days, days.id.equalsExp(sessions.programDayId)),
      leftOuterJoin(
        logs,
        logs.sessionId.equalsExp(sessions.id) & logs.actualReps.isNotNull(),
      ),
    ])
      ..addColumns([setsLogged, topSet, volume])
      ..where(sessions.completedAt.isNotNull())
      ..groupBy([sessions.id])
      ..orderBy([
        OrderingTerm(
          expression: sessions.completedAt,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map(
          (rows) => rows.map((row) {
            final session = row.readTable(sessions);
            return HistoryEntry(
              sessionId: session.id,
              date: session.completedAt!,
              dayName: row.readTableOrNull(days)?.name ?? 'Workout',
              setsLogged: row.read(setsLogged) ?? 0,
              topSetKg: row.read(topSet),
              totalVolumeKg: row.read(volume) ?? 0,
            );
          }).toList(),
        );
  }
}
