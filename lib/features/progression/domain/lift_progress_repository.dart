import 'package:openlifts/core/database/app_database.dart';

/// Per-exercise progression state (global; persists across program switches).
abstract interface class LiftProgressRepository {
  Future<LiftProgress?> get(String exerciseId);

  /// Batch [get]: the progress rows for [exerciseIds], keyed by exercise id.
  /// Exercises with no recorded progress are simply absent from the map.
  Future<Map<String, LiftProgress>> getMany(List<String> exerciseIds);

  /// Every recorded lift-progress row (used to deload all lifts at once).
  Future<List<LiftProgress>> getAll();

  Future<void> upsert({
    required String exerciseId,
    required double workingWeightKg,
    required DateTime updatedAt,
    int consecutiveFailures = 0,
  });
}
