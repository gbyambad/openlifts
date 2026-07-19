import 'package:drift/drift.dart' show Value;
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';
import 'package:openlifts/features/progression/application/progression_providers.dart';
import 'package:openlifts/features/progression/domain/default_anchor.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'program_weights.g.dart';

class WeightEntry {
  const WeightEntry({
    required this.exerciseId,
    required this.name,
    required this.workingKg,
    required this.type,
    required this.sets,
    required this.reps,
  });

  final String exerciseId;
  final String name;
  final double workingKg;
  final SetSchemeType type;
  final int sets;
  final int reps;
}

class WorkoutWeights {
  const WorkoutWeights({required this.dayName, required this.entries});

  final String dayName;
  final List<WeightEntry> entries;
}

/// The active program's working weights, grouped by workout — the source for
/// the Programs "Weights" tab.
class ProgramWeights {
  const ProgramWeights({
    required this.workouts,
    required this.unit,
    required this.barWeightKg,
  });

  final List<WorkoutWeights> workouts;
  final Unit unit;
  final double barWeightKg;
}

@riverpod
Future<ProgramWeights?> programWeights(Ref ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final programId = settings.activeProgramId;
  if (programId == null) return null;
  final tree = await ref.watch(programRepositoryProvider).loadTree(programId);
  if (tree == null) return null;

  final progress = ref.watch(liftProgressRepositoryProvider);
  final progressById = await progress.getMany([
    for (final day in tree.days)
      for (final p in day.prescriptions) p.exercise.id,
  ]);
  final workouts = <WorkoutWeights>[];
  for (final day in tree.days) {
    final entries = <WeightEntry>[];
    for (final p in day.prescriptions) {
      final scheme = schemeFromGroups(p.setGroups);
      entries.add(
        WeightEntry(
          exerciseId: p.exercise.id,
          name: p.exercise.name,
          workingKg: defaultAnchorKg(
            workingWeightKg: progressById[p.exercise.id]?.workingWeightKg,
            startsLoaded: p.exercise.startsLoaded,
          ),
          type: scheme.type,
          sets: scheme.sets,
          reps: scheme.reps,
        ),
      );
    }
    workouts.add(WorkoutWeights(dayName: day.day.name, entries: entries));
  }
  return ProgramWeights(
    workouts: workouts,
    unit: settings.unit,
    barWeightKg: settings.barWeightKg,
  );
}

/// Edits a lift's working weight (shared with progression state).
///
/// Kept alive: an action-only controller reached via `ref.read(...notifier)`
/// with no listener. Auto-dispose would tear it down before an edit's async
/// write completes, throwing `UnmountedRefException` mid-write (same footgun
/// fixed on `SettingsController`).
@Riverpod(keepAlive: true)
class ProgramWeightsController extends _$ProgramWeightsController {
  @override
  void build() {}

  Future<void> setWeight(String exerciseId, double kg) async {
    final repo = ref.read(liftProgressRepositoryProvider);
    final existing = await repo.get(exerciseId);
    await repo.upsert(
      exerciseId: exerciseId,
      workingWeightKg: kg,
      consecutiveFailures: existing?.consecutiveFailures ?? 0,
      updatedAt: DateTime.now(),
    );
    ref
      ..invalidate(programWeightsProvider)
      ..invalidate(todayProvider);
  }

  /// Changes an exercise's set scheme in the active program (forking a built-in
  /// into a custom copy, which then becomes active).
  Future<void> setScheme(
    String exerciseId,
    SetSchemeType type,
    int sets,
    int reps,
  ) async {
    final settings = ref.read(settingsRepositoryProvider);
    final programId = (await settings.get()).activeProgramId;
    if (programId == null) return;

    final targetId =
        await ref.read(programRepositoryProvider).setExerciseScheme(
              programId,
              exerciseId,
              buildSetGroups(type, sets, reps),
            );
    if (targetId != programId) {
      await settings.save(SettingsCompanion(activeProgramId: Value(targetId)));
    }
    ref
      ..invalidate(programWeightsProvider)
      ..invalidate(programsViewProvider)
      ..invalidate(todayProvider);
  }
}
