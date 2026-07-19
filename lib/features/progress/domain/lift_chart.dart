import 'package:openlifts/features/sessions/domain/session_repository.dart';

/// One plotted point: the top (heaviest) set of a lift on a given day.
class WeightPoint {
  const WeightPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

/// A single lift's weight-over-time series, ready to plot.
class LiftChart {
  const LiftChart({
    required this.exerciseId,
    required this.name,
    required this.points,
  });

  final String exerciseId;
  final String name;
  final List<WeightPoint> points;
}

/// Collapse raw per-set points into one chart per exercise, keeping the
/// heaviest set per calendar day (the top set is the meaningful progress
/// signal). [names] maps exercise id -> display name; unknown ids fall back to
/// the id. Charts are ordered by how recently the lift was trained.
List<LiftChart> buildLiftCharts(
  List<LiftSeriesPoint> points,
  Map<String, String> names,
) {
  // exerciseId -> (dayEpoch -> best point)
  final byExercise = <String, Map<int, WeightPoint>>{};
  for (final p in points) {
    final day = DateTime(p.date.year, p.date.month, p.date.day);
    final dayKey = day.millisecondsSinceEpoch;
    final perDay = byExercise.putIfAbsent(p.exerciseId, () => {});
    final existing = perDay[dayKey];
    if (existing == null || p.weightKg > existing.weightKg) {
      perDay[dayKey] = WeightPoint(date: day, weightKg: p.weightKg);
    }
  }

  final charts = byExercise.entries.map((entry) {
    final series = entry.value.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return LiftChart(
      exerciseId: entry.key,
      name: names[entry.key] ?? entry.key,
      points: series,
    );
  }).toList()
    ..sort((a, b) => b.points.last.date.compareTo(a.points.last.date));

  return charts;
}
