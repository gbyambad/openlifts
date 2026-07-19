import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';

void main() {
  LiftSeriesPoint point(String id, DateTime d, double kg) =>
      LiftSeriesPoint(exerciseId: id, date: d, weightKg: kg);

  test('keeps the heaviest set per day and orders oldest-first', () {
    final day1 = DateTime(2026, 1, 1, 9);
    final day2 = DateTime(2026, 1, 3, 9);
    final charts = buildLiftCharts(
      [
        point('squat', day1, 60),
        point('squat', DateTime(2026, 1, 1, 9, 30), 62.5), // same day, heavier
        point('squat', day2, 65),
      ],
      {'squat': 'Squat'},
    );

    expect(charts, hasLength(1));
    final squat = charts.single;
    expect(squat.name, 'Squat');
    expect(squat.points.map((p) => p.weightKg), [62.5, 65]);
  });

  test('orders lifts by most recently trained', () {
    final charts = buildLiftCharts(
      [
        point('squat', DateTime(2026), 60),
        point('bench', DateTime(2026, 1, 5), 40),
      ],
      {'squat': 'Squat', 'bench': 'Bench Press'},
    );

    expect(charts.map((c) => c.exerciseId), ['bench', 'squat']);
  });

  test('falls back to the exercise id when no name is known', () {
    final charts = buildLiftCharts(
      [point('mystery', DateTime(2026), 20)],
      {},
    );
    expect(charts.single.name, 'mystery');
  });
}
