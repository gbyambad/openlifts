import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/home/domain/rotation.dart';

part 'schedule.freezed.dart';

/// A computed upcoming workout: a date paired with its rotation day index.
@freezed
abstract class UpcomingWorkout with _$UpcomingWorkout {
  const factory UpcomingWorkout({
    required DateTime date,
    required int dayIndex,
  }) = _UpcomingWorkout;
}

/// StrongLifts auto-assigns rest days for a frequency schedule.
Set<int> _autoWeekdays(int timesPerWeek) {
  switch (timesPerWeek) {
    case 1:
      return {DateTime.monday};
    case 2:
      return {DateTime.monday, DateTime.thursday};
    case 3:
      return {DateTime.monday, DateTime.wednesday, DateTime.friday};
    case 4:
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.thursday,
        DateTime.friday,
      };
    case 5:
      return {
        DateTime.monday,
        DateTime.tuesday,
        DateTime.wednesday,
        DateTime.thursday,
        DateTime.friday,
      };
    default:
      return {1, 2, 3, 4, 5, 6};
  }
}

/// The next [count] workout dates from [from], per the schedule mode.
List<DateTime> upcomingDates({
  required ScheduleMode mode,
  required DateTime from,
  int count = 3,
  int? timesPerWeek,
  int? everyNDays,
  List<int>? weekdays,
  DateTime? lastWorkout,
}) {
  final result = <DateTime>[];

  if (mode == ScheduleMode.everyNDays) {
    final step = everyNDays ?? 2;
    var d = lastWorkout != null ? lastWorkout.add(Duration(days: step)) : from;
    while (result.length < count) {
      result.add(d);
      d = d.add(Duration(days: step));
    }
    return result;
  }

  final days = mode == ScheduleMode.timesPerWeek
      ? _autoWeekdays(timesPerWeek ?? 3)
      : (weekdays ?? const [1, 3, 5]).toSet();
  var d = from;
  while (result.length < count) {
    if (days.contains(d.weekday)) result.add(d);
    d = d.add(const Duration(days: 1));
  }
  return result;
}

/// The next [count] workouts: upcoming dates paired with the rotation day that
/// lands on each (the rotation continues cyclically from history).
List<UpcomingWorkout> upcomingWorkouts({
  required ScheduleMode mode,
  required DateTime from,
  required int dayCount,
  int? lastCompletedIndex,
  int count = 3,
  int? timesPerWeek,
  int? everyNDays,
  List<int>? weekdays,
  DateTime? lastWorkout,
}) {
  final dates = upcomingDates(
    mode: mode,
    from: from,
    count: count,
    timesPerWeek: timesPerWeek,
    everyNDays: everyNDays,
    weekdays: weekdays,
    lastWorkout: lastWorkout,
  );
  var idx = nextDayIndex(dayCount, lastCompletedIndex);
  final result = <UpcomingWorkout>[];
  for (final date in dates) {
    result.add(UpcomingWorkout(date: date, dayIndex: idx));
    idx = (idx + 1) % dayCount;
  }
  return result;
}
