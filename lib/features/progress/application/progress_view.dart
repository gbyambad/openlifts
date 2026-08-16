import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/bodyweight/application/bodyweight_providers.dart';
import 'package:openlifts/features/exercises/application/exercises_providers.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_view.g.dart';

/// Everything the progress screen renders: a chart per trained lift, the
/// bodyweight series, completed-workout history, and the display unit.
class ProgressData {
  const ProgressData({
    required this.charts,
    required this.bodyweight,
    required this.history,
    required this.unit,
  });

  final List<LiftChart> charts;
  final List<WeightPoint> bodyweight;
  final List<HistoryEntry> history;
  final Unit unit;
}

@riverpod
Future<ProgressData> progressView(Ref ref) async {
  final series = await ref.watch(liftSeriesProvider.future);
  final exercises = await ref.watch(exercisesProvider.future);
  final bodyweight = await ref.watch(bodyweightSeriesProvider.future);
  final history = await ref.watch(historyProvider.future);
  final settings = await ref.watch(settingsProvider.future);

  return ProgressData(
    charts: buildLiftCharts(series, {for (final e in exercises) e.id: e.name}),
    bodyweight: [
      for (final e in bodyweight)
        WeightPoint(date: e.loggedAt, weightKg: e.weightKg),
    ],
    history: history,
    unit: settings.unit,
  );
}
