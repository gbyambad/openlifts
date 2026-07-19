import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/home/domain/rotation.dart';
import 'package:openlifts/features/home/domain/schedule.dart';

void main() {
  test('rotation: first workout is day A, then alternates', () {
    expect(nextDayIndex(2, null), 0); // fresh start -> A
    expect(nextDayIndex(2, 0), 1); // A -> B
    expect(nextDayIndex(2, 1), 0); // B -> A
  });

  test('timesPerWeek=3 gives 3 upcoming workouts, A/B/A on Mon/Wed/Fri', () {
    final ws = upcomingWorkouts(
      mode: ScheduleMode.timesPerWeek,
      from: DateTime(2026, 7, 20), // a Monday
      dayCount: 2,
      timesPerWeek: 3,
    );
    const workoutDays = {DateTime.monday, DateTime.wednesday, DateTime.friday};
    expect(ws.length, 3);
    expect(ws.map((w) => w.dayIndex).toList(), [0, 1, 0]);
    expect(ws.every((w) => workoutDays.contains(w.date.weekday)), isTrue);
  });

  test('everyNDays computes the next dates from the last workout', () {
    final dates = upcomingDates(
      mode: ScheduleMode.everyNDays,
      from: DateTime(2026, 7, 18),
      everyNDays: 2,
      lastWorkout: DateTime(2026, 7, 18),
      count: 2,
    );
    expect(dates, [DateTime(2026, 7, 20), DateTime(2026, 7, 22)]);
  });
}
