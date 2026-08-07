import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/date/date_labels.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/home/domain/schedule.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/features/progression/application/progression_providers.dart';
import 'package:openlifts/features/progression/domain/default_anchor.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'today_providers.g.dart';

/// The home view: the active program's next few scheduled workouts, each with
/// its exercises and the exact loads to hit. Null when no program is active.
class TodayView {
  const TodayView({
    required this.programName,
    required this.unit,
    required this.workouts,
  });

  final String programName;
  final Unit unit;
  final List<PlannedWorkout> workouts;
}

/// One upcoming session on the schedule.
class PlannedWorkout {
  const PlannedWorkout({
    required this.dayId,
    required this.dayName,
    required this.dateLabel,
    required this.exercises,
    required this.isNext,
  });

  final String dayId;
  final String dayName;
  final String dateLabel; // "Today", "Tomorrow", "Wed, Jul 23"
  final List<PlannedExercise> exercises;
  final bool isNext; // the nearest workout carries the Start button
}

class PlannedExercise {
  const PlannedExercise({required this.name, required this.scheme});

  final String name;
  final String scheme; // "5×5 60 kg" or "3×72.5 kg, 4×3 65 kg"
}

@riverpod
Future<TodayView?> today(Ref ref) async {
  final loc = ref.watch(appLocalizationsProvider);
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final programId = settings.activeProgramId;
  if (programId == null) return null;

  final tree = await ref.watch(programRepositoryProvider).loadTree(programId);
  if (tree == null || tree.days.isEmpty) return null;

  // Where the rotation stands: the day after the last completed session's day.
  final sessions =
      await ref.watch(sessionRepositoryProvider).watchRecent().first;
  final dayIds = [for (final d in tree.days) d.day.id];
  int? lastIndex;
  DateTime? lastWorkout;
  for (final s in sessions) {
    if (s.completedAt != null) {
      final i = dayIds.indexOf(s.programDayId);
      if (i >= 0) {
        lastIndex = i;
        lastWorkout = s.completedAt;
        break;
      }
    }
  }

  final program = tree.program;
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, now.day);
  final upcoming = upcomingWorkouts(
    mode: program.scheduleMode,
    from: from,
    dayCount: tree.days.length,
    lastCompletedIndex: lastIndex,
    timesPerWeek: program.timesPerWeek,
    everyNDays: program.everyNDays,
    weekdays: program.weekdays,
    lastWorkout: lastWorkout,
  );

  final progress = ref.watch(liftProgressRepositoryProvider);
  final upcomingDays = [for (final u in upcoming) tree.days[u.dayIndex]];
  final progressById = await progress.getMany([
    for (final day in upcomingDays)
      for (final p in day.prescriptions) p.exercise.id,
  ]);
  final workouts = <PlannedWorkout>[];
  for (var i = 0; i < upcoming.length; i++) {
    final day = upcomingDays[i];
    final exercises = <PlannedExercise>[];
    for (final p in day.prescriptions) {
      final anchor = defaultAnchorKg(
        workingWeightKg: progressById[p.exercise.id]?.workingWeightKg,
        startsLoaded: p.exercise.startsLoaded,
      );
      exercises.add(
        PlannedExercise(
          name: p.exercise.name,
          scheme: _scheme(p.setGroups, anchor, settings.unit),
        ),
      );
    }
    workouts.add(
      PlannedWorkout(
        dayId: day.day.id,
        dayName: day.day.name,
        dateLabel: _dateLabel(loc, from, upcoming[i].date),
        exercises: exercises,
        isNext: i == 0,
      ),
    );
  }

  return TodayView(
    programName: program.name,
    unit: settings.unit,
    workouts: workouts,
  );
}

/// Formats a prescription's set-groups as "top, back-off" load segments, e.g.
/// "5×5 60 kg" (straight) or "3×72.5 kg, 4×3 65 kg" (top set + back-off).
String _scheme(List<SetGroup> groups, double anchor, Unit unit) {
  final parts = <String>[];
  for (final g in groups) {
    final resolved = resolveSetGroup(
      anchor,
      SetGroupSpec(
        sets: g.sets,
        reps: g.reps,
        weightRule: g.weightRule,
        weightParam: g.weightParam,
      ),
    );
    if (resolved.isEmpty) continue;
    final w = weightLabel(resolved.first.weightKg, unit);
    parts.add(g.sets == 1 ? '${g.reps}×$w' : '${g.sets}×${g.reps} $w');
  }
  return parts.join(', ');
}

String _dateLabel(AppLocalizations loc, DateTime from, DateTime date) {
  final days = date.difference(from).inDays;
  if (days <= 0) return loc.today;
  if (days == 1) return loc.tomorrow;
  final weekday = weekdayShort(loc, date.weekday);
  return '$weekday, ${monthShort(loc, date.month)} ${date.day}';
}
