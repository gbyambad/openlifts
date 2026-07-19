import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/exercises/application/exercises_providers.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exercise_detail.g.dart';

/// One exercise plus its recent top-set history. Null when the id is unknown.
class ExerciseDetailData {
  const ExerciseDetailData({
    required this.exercise,
    required this.history,
    required this.unit,
  });

  final Exercise exercise;
  final List<WeightPoint> history;
  final Unit unit;
}

@riverpod
Future<ExerciseDetailData?> exerciseDetail(Ref ref, String exerciseId) async {
  final all = await ref.watch(exercisesProvider.future);
  final exercise = all.where((e) => e.id == exerciseId).firstOrNull;
  if (exercise == null) return null;

  final series = await ref.watch(liftSeriesProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  final chart = buildLiftCharts(
    series.where((p) => p.exerciseId == exerciseId).toList(),
    {exerciseId: exercise.name},
  ).firstOrNull;

  return ExerciseDetailData(
    exercise: exercise,
    history: chart?.points ?? const [],
    unit: settings.unit,
  );
}
