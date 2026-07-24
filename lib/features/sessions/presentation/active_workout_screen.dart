import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/sessions/presentation/active_workout_view.dart';
import 'package:openlifts/features/sessions/presentation/workout_summary_sheet.dart';
import 'package:openlifts/shared/widgets/confirm_dialog.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Runs a workout for [dayId]: watches the controller and wires the view's
/// callbacks to it, then pops on finish.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({required this.dayId, super.key});

  final String dayId;

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    // Keep the screen awake through the session — a phone locking between sets
    // is the classic gym-tracker annoyance.
    unawaited(WakelockPlus.enable());
  }

  @override
  void dispose() {
    unawaited(WakelockPlus.disable());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dayId = widget.dayId;
    final async = ref.watch(activeWorkoutControllerProvider(dayId));
    return async.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not start workout.\n$e')),
      ),
      data: (state) {
        // Guard an accidental back-out that would discard logged-but-unsaved
        // work (the session only persists on Finish).
        final hasProgress =
            state.lifts.any((l) => l.workingSets.any((s) => s.logged));
        return PopScope(
          canPop: !hasProgress,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final leave = await showConfirmDialog(
              context,
              title: 'Leave workout?',
              message: 'Your logged sets will be discarded — '
                  'finish the workout to save them.',
              cancelLabel: 'Keep going',
              confirmLabel: 'Leave',
            );
            if (leave == true && context.mounted) context.pop();
          },
          child: ActiveWorkoutView(
            state: state,
            onCycleSet: (li, si) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .cycleSet(li, si),
            onSetWeight: (li, kg) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .setLiftWeight(li, kg),
            onSetWeightFrom: (li, si, kg) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .setSetWeightFrom(li, si, kg),
            onAddSet: (li) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .addSet(li),
            onRemoveSet: (li) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .removeSet(li),
            onDeload: (li) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .deloadLift(li),
            onLogBodyweight: (kg) => ref
                .read(activeWorkoutControllerProvider(dayId).notifier)
                .logBodyweight(kg),
            onSwitchDay: (id) => context.go('/today/workout/$id'),
            onFinish: () => _finish(context, ref, state),
          ),
        );
      },
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

    await ref
        .read(activeWorkoutControllerProvider(widget.dayId).notifier)
        .finish();
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
