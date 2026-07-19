import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/exercises/data/exercise_repository_impl.dart';
import 'package:openlifts/features/exercises/domain/exercise_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercises_providers.g.dart';

@riverpod
ExerciseRepository exerciseRepository(Ref ref) =>
    DriftExerciseRepository(ref.watch(appDatabaseProvider));

/// Reactive exercise catalog. Hand-written `StreamProvider` because
/// riverpod_generator can't reference the Drift-generated `Exercise` type.
final exercisesProvider = StreamProvider<List<Exercise>>(
  (ref) => ref.watch(exerciseRepositoryProvider).watchAll(),
);
