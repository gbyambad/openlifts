import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';

/// Returns the Drift [Exercise] row directly; a separate domain model is added
/// only where a shape diverges from the stored row.
abstract interface class ExerciseRepository {
  /// Reactive stream of the full catalog, ordered by name.
  Stream<List<Exercise>> watchAll();

  Future<Exercise?> findById(String id);

  /// Batch [findById]: the exercises for [ids], keyed by id. Ids with no match
  /// are simply absent from the map.
  Future<Map<String, Exercise>> findByIds(List<String> ids);

  /// The primary muscles tagged for an exercise.
  Future<List<Muscle>> primaryMusclesFor(String exerciseId);

  /// Exercises that target [muscle] (primary or secondary).
  Future<List<Exercise>> byMuscle(Muscle muscle);
}
