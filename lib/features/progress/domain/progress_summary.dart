import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';

/// Keep only the workouts completed on or after the start of [range],
/// relative to [now].
List<HistoryEntry> filterHistoryByRange(
  List<HistoryEntry> history,
  ProgressRange range,
  DateTime now,
) {
  final days = range.days;
  if (days == null) return history;
  final cutoff = now.subtract(Duration(days: days));
  return [
    for (final h in history)
      if (!h.date.isBefore(cutoff)) h,
  ];
}

/// Total tonnage lifted per day, oldest-first. Reuses [WeightPoint]'s shape
/// (a kg magnitude over time) so it can be plotted with the same chart card
/// used for lifts and bodyweight.
List<WeightPoint> buildVolumeSeries(List<HistoryEntry> history) {
  final byDay = <int, double>{};
  for (final h in history) {
    final day = DateTime(h.date.year, h.date.month, h.date.day);
    final dayKey = day.millisecondsSinceEpoch;
    byDay[dayKey] = (byDay[dayKey] ?? 0) + h.totalVolumeKg;
  }

  final points = [
    for (final entry in byDay.entries)
      WeightPoint(
        date: DateTime.fromMillisecondsSinceEpoch(entry.key),
        weightKg: entry.value,
      ),
  ]..sort((a, b) => a.date.compareTo(b.date));

  return points;
}

/// Top-line stats for the selected range: how much was trained, and how much
/// progress was made.
class ProgressSummary {
  const ProgressSummary({
    required this.workoutCount,
    required this.totalVolumeKg,
    this.strengthChangePercent,
    this.bodyweightChangeKg,
  });

  final int workoutCount;
  final double totalVolumeKg;

  /// Average % change of each lift's top set, first-vs-last within the
  /// range. Null when no lift has at least two points in range.
  final double? strengthChangePercent;

  /// Bodyweight change (last minus first) within the range. Null when there
  /// aren't at least two bodyweight entries in range.
  final double? bodyweightChangeKg;
}

/// Builds the "Overall" stat tiles from raw (unfiltered) progress data,
/// scoping every stat to [range] as of [now].
ProgressSummary buildProgressSummary({
  required List<HistoryEntry> history,
  required List<LiftChart> charts,
  required List<WeightPoint> bodyweight,
  required ProgressRange range,
  required DateTime now,
}) {
  final historyInRange = filterHistoryByRange(history, range, now);
  final totalVolumeKg = historyInRange.fold<double>(
    0,
    (sum, h) => sum + h.totalVolumeKg,
  );

  final changes = <double>[];
  for (final chart in charts) {
    final points = filterPointsByRange(chart.points, range, now);
    if (points.length < 2) continue;
    final first = points.first.weightKg;
    if (first <= 0) continue;
    changes.add((points.last.weightKg - first) / first * 100);
  }
  final strengthChangePercent =
      changes.isEmpty ? null : changes.reduce((a, b) => a + b) / changes.length;

  final bwInRange = filterPointsByRange(bodyweight, range, now);
  final bodyweightChangeKg = bwInRange.length < 2
      ? null
      : bwInRange.last.weightKg - bwInRange.first.weightKg;

  return ProgressSummary(
    workoutCount: historyInRange.length,
    totalVolumeKg: totalVolumeKg,
    strengthChangePercent: strengthChangePercent,
    bodyweightChangeKg: bodyweightChangeKg,
  );
}

/// A lift's best-ever top set.
class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.name,
    required this.bestWeightKg,
    required this.isRecent,
  });

  final String exerciseId;
  final String name;
  final double bestWeightKg;

  /// True when the most recently logged top set is (tied for) the all-time
  /// best — i.e. this lift is still trending up.
  final bool isRecent;
}

/// All-time bests per lift, independent of the selected range — a record set
/// last year is still a record. Ordered the same as [charts] (most recently
/// trained first).
List<PersonalRecord> buildPersonalRecords(List<LiftChart> charts) {
  final records = <PersonalRecord>[];
  for (final chart in charts) {
    if (chart.points.isEmpty) continue;
    final best =
        chart.points.map((p) => p.weightKg).reduce((a, b) => a > b ? a : b);
    records.add(
      PersonalRecord(
        exerciseId: chart.exerciseId,
        name: chart.name,
        bestWeightKg: best,
        isRecent: chart.points.last.weightKg == best,
      ),
    );
  }
  return records;
}
