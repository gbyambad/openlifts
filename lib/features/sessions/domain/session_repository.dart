import 'package:openlifts/core/database/app_database.dart';

/// One logged set flattened against its (completed) session date, for plotting
/// per-lift progress over time.
class LiftSeriesPoint {
  const LiftSeriesPoint({
    required this.exerciseId,
    required this.date,
    required this.weightKg,
  });

  final String exerciseId;
  final DateTime date;
  final double weightKg;
}

/// A completed workout summarised for the history list.
class HistoryEntry {
  const HistoryEntry({
    required this.sessionId,
    required this.date,
    required this.dayName,
    required this.setsLogged,
    this.topSetKg,
    this.totalVolumeKg = 0,
  });

  final int sessionId;
  final DateTime date;
  final String dayName;
  final int setsLogged;
  final double? topSetKg;

  /// Total tonnage lifted in the session (sum of weight × reps across sets).
  final double totalVolumeKg;
}

/// Logs performed workouts and their sets.
abstract interface class SessionRepository {
  Future<int> startSession(String programDayId, DateTime startedAt);

  Future<void> logSet({
    required int sessionId,
    required String exerciseId,
    required int setIndex,
    required double weightKg,
    required int targetReps,
    int? actualReps,
  });

  Future<void> completeSession(int sessionId, DateTime completedAt);

  Future<List<SetLog>> setsFor(int sessionId);

  Stream<List<WorkoutSession>> watchRecent({int limit = 20});

  /// Every logged set from completed sessions, oldest-first, for charting.
  Stream<List<LiftSeriesPoint>> watchLiftSeries();

  /// Completed workouts summarised for history, newest-first.
  Stream<List<HistoryEntry>> watchHistory();
}
