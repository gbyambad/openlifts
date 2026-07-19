import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'program_detail.g.dart';

/// One workout in a program, reduced to its name and exercise lines.
class WorkoutOutline {
  const WorkoutOutline({required this.name, required this.exercises});

  final String name;
  final List<String> exercises; // e.g. "Squat  5×5"
}

/// A program's structure plus its current training-day schedule.
class ProgramDetail {
  const ProgramDetail({
    required this.id,
    required this.name,
    required this.isActive,
    required this.weekdays,
    required this.workouts,
  });

  final String id;
  final String name;
  final bool isActive;
  final List<int> weekdays; // 1 = Mon … 7 = Sun
  final List<WorkoutOutline> workouts;
}

@riverpod
Future<ProgramDetail?> programDetail(Ref ref, String programId) async {
  final tree = await ref.watch(programRepositoryProvider).loadTree(programId);
  if (tree == null) return null;
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final p = tree.program;

  return ProgramDetail(
    id: p.id,
    name: p.name,
    isActive: settings.activeProgramId == p.id,
    weekdays: p.weekdays ?? const [1, 3, 5], // default Mon/Wed/Fri
    workouts: [
      for (final d in tree.days)
        WorkoutOutline(
          name: d.day.name,
          exercises: [
            for (final pr in d.prescriptions)
              '${pr.exercise.name}  ${_scheme(pr.setGroups)}',
          ],
        ),
    ],
  );
}

String _scheme(List<SetGroup> groups) =>
    groups.map((g) => '${g.sets}×${g.reps}').join(', ');
