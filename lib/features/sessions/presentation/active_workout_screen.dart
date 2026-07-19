import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_view.dart';
import 'package:openlifts/features/sessions/presentation/workout_summary_sheet.dart';
import 'package:openlifts/shared/widgets/confirm_dialog.dart';

/// Runs a workout for [dayId]: watches the controller and wires the view's
/// callbacks to it, then pops on finish.
class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({required this.dayId, super.key});

  final String dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activeWorkoutControllerProvider(dayId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not start workout.\n$e')),
      ),
      data: (state) => ActiveWorkoutView(
        state: state,
        onCycleSet: (li, si) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .cycleSet(li, si),
        onSetWeight: (li, kg) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .setLiftWeight(li, kg),
        onSetWeightAt: (li, si, kg) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .setSetWeight(li, si, kg),
        onAddSet: (li) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .addSet(li),
        onRemoveSet: (li) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .removeSet(li),
        onLogBodyweight: (kg) => ref
            .read(activeWorkoutControllerProvider(dayId).notifier)
            .logBodyweight(kg),
        onSwitchDay: (id) => context.go('/today/workout/$id'),
        onFinish: () => _finish(context, ref, state),
      ),
    );
  }

  /// Confirms if sets are unlogged, saves the session, then shows a summary.
  Future<void> _finish(
    BuildContext context,
    WidgetRef ref,
    WorkoutState state,
  ) async {
    final allSets = [for (final l in state.lifts) ...l.workingSets];
    final unlogged = allSets.where((s) => !s.logged).length;

    if (unlogged > 0) {
      final proceed = await showConfirmDialog(
        context,
        title: 'Finish workout?',
        message:
            '$unlogged ${unlogged == 1 ? 'set is' : 'sets are'} not logged. '
            'Only logged sets are saved.',
        cancelLabel: 'Keep going',
        confirmLabel: 'Finish',
      );
      if (proceed != true) return;
    }
    if (!context.mounted) return;

    final logged = allSets.where((s) => s.logged);
    final volume = logged.fold<double>(
      0,
      (v, s) => v + s.weightKg * (s.actualReps ?? 0),
    );

    await ref.read(activeWorkoutControllerProvider(dayId).notifier).finish();
    if (!context.mounted) return;

    await showWorkoutSummary(
      context,
      dayName: state.dayName,
      setsDone: logged.length,
      volumeKg: volume,
      unit: state.unit,
    );
    if (context.mounted) context.pop();
  }
}
