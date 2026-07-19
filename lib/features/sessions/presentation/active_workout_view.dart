import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/workout/domain/plate_math.dart';
import 'package:openlifts/shared/widgets/plate_bar.dart';

/// Presentational active-workout UI. Pure (no providers/DB) so it is
/// widget-testable directly with a fixed [WorkoutState] and callbacks.
class ActiveWorkoutView extends StatefulWidget {
  const ActiveWorkoutView({
    required this.state,
    required this.onCycleSet,
    required this.onSetWeight,
    required this.onSetWeightAt,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onLogBodyweight,
    required this.onSwitchDay,
    required this.onFinish,
    super.key,
  });

  final WorkoutState state;
  final void Function(int liftIndex, int setIndex) onCycleSet;
  final void Function(int liftIndex, double anchorKg) onSetWeight;

  /// Override one set's weight (top set or a back-off) without touching the
  /// lift's anchor or the other sets.
  final void Function(int liftIndex, int setIndex, double weightKg)
      onSetWeightAt;
  final void Function(int liftIndex) onAddSet;
  final void Function(int liftIndex) onRemoveSet;
  final void Function(double weightKg) onLogBodyweight;
  final void Function(String dayId) onSwitchDay;
  final VoidCallback onFinish;

  @override
  State<ActiveWorkoutView> createState() => _ActiveWorkoutViewState();
}

class _ActiveWorkoutViewState extends State<ActiveWorkoutView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// Warmup sets checked off this session, keyed "liftIndex-warmupIndex".
  /// Held here (not inside the row) so the marks survive tab switches.
  final Set<String> _doneWarmups = {};

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  int get _warmupTotal =>
      widget.state.lifts.fold(0, (n, l) => n + l.warmups.length);

  void _toggleWarmup(String key) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_doneWarmups.add(key)) _doneWarmups.remove(key);
    });
    // Warmups all checked -> move on to the working sets.
    if (_warmupTotal > 0 &&
        _doneWarmups.length >= _warmupTotal &&
        _tabs.index != 0) {
      _tabs.animateTo(0);
    }
  }

  bool _laterLiftHasPendingWarmup(int afterLift) {
    for (var li = afterLift + 1; li < widget.state.lifts.length; li++) {
      for (var wi = 0; wi < widget.state.lifts[li].warmups.length; wi++) {
        if (!_doneWarmups.contains('$li-$wi')) return true;
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(ActiveWorkoutView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When a lift's working sets just became fully logged and a later lift
    // still needs warming up, nudge over to the Warmup tab.
    final lifts = widget.state.lifts;
    final old = oldWidget.state.lifts;
    for (var li = 0; li < lifts.length; li++) {
      final done = lifts[li].workingSets.isNotEmpty &&
          lifts[li].workingSets.every((s) => s.logged);
      final wasDone = li < old.length &&
          old[li].workingSets.isNotEmpty &&
          old[li].workingSets.every((s) => s.logged);
      if (done && !wasDone && _laterLiftHasPendingWarmup(li)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabs.index != 1) _tabs.animateTo(1);
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return Scaffold(
      appBar: AppBar(
        title: state.days.length <= 1
            ? Text(state.dayName)
            : PopupMenuButton<String>(
                tooltip: 'Switch workout',
                initialValue: state.dayId,
                onSelected: widget.onSwitchDay,
                itemBuilder: (context) => [
                  for (final d in state.days)
                    PopupMenuItem(value: d.id, child: Text(d.name)),
                ],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.dayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
        actions: [
          TextButton(onPressed: widget.onFinish, child: const Text('Finish')),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'Workout'), Tab(text: 'Warmup')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _WorkoutTab(
            state: state,
            onCycleSet: widget.onCycleSet,
            onSetWeight: widget.onSetWeight,
            onSetWeightAt: widget.onSetWeightAt,
            onAddSet: widget.onAddSet,
            onRemoveSet: widget.onRemoveSet,
            onLogBodyweight: widget.onLogBodyweight,
          ),
          _WarmupTab(
            state: state,
            doneWarmups: _doneWarmups,
            onToggleWarmup: _toggleWarmup,
          ),
        ],
      ),
    );
  }
}

class _WorkoutTab extends StatefulWidget {
  const _WorkoutTab({
    required this.state,
    required this.onCycleSet,
    required this.onSetWeight,
    required this.onSetWeightAt,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onLogBodyweight,
  });

  final WorkoutState state;
  final void Function(int, int) onCycleSet;
  final void Function(int, double) onSetWeight;
  final void Function(int, int, double) onSetWeightAt;
  final void Function(int) onAddSet;
  final void Function(int) onRemoveSet;
  final void Function(double) onLogBodyweight;

  @override
  State<_WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<_WorkoutTab> {
  Timer? _timer;
  int _restRemaining = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Called after a set is logged: (re)start the rest countdown.
  void _startRest() {
    _timer?.cancel();
    setState(() => _restRemaining = widget.state.restSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_restRemaining <= 1) {
        t.cancel();
        setState(() => _restRemaining = 0);
        unawaited(HapticFeedback.heavyImpact()); // buzz when rest is up
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  void _dismissRest() {
    _timer?.cancel();
    setState(() => _restRemaining = 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final allSets = [for (final l in state.lifts) ...l.workingSets];
    final doneSets = allSets.where((s) => s.logged).length;
    return Column(
      children: [
        _ProgressHeader(done: doneSets, total: allSets.length),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            children: [
              for (var li = 0; li < state.lifts.length; li++)
                _LiftCard(
                  lift: state.lifts[li],
                  unit: state.unit,
                  onCycle: (si, {required wasLogged}) {
                    unawaited(HapticFeedback.selectionClick());
                    widget.onCycleSet(li, si);
                    if (!wasLogged) _startRest();
                  },
                  onEditWeight: () => _editWeight(context, li, state.lifts[li]),
                  onEditSetWeight: (si) =>
                      _editSetWeight(context, li, state.lifts[li], si),
                  onAddSet: () => widget.onAddSet(li),
                  onRemoveSet: () => widget.onRemoveSet(li),
                ),
              _BodyweightRow(
                currentKg: state.bodyweightKg,
                unit: state.unit,
                onTap: () => _logBodyweight(context),
              ),
            ],
          ),
        ),
        if (_restRemaining > 0)
          _RestBar(
            remaining: _restRemaining,
            total: state.restSeconds,
            onDismiss: _dismissRest,
          ),
      ],
    );
  }

  Future<void> _editWeight(BuildContext context, int li, ActiveLift lift) {
    return showWeightEditor(
      context,
      title: '${lift.name} — working weight',
      initialKg: lift.anchorKg,
      unit: widget.state.unit,
      barKg: widget.state.barWeightKg,
      onChanged: (kg) => widget.onSetWeight(li, kg),
    );
  }

  Future<void> _editSetWeight(
    BuildContext context,
    int li,
    ActiveLift lift,
    int setIndex,
  ) {
    final target = lift.workingSets.firstWhere((ws) => ws.index == setIndex);
    return showWeightEditor(
      context,
      title: '${lift.name} — set ${setIndex + 1} weight',
      initialKg: target.weightKg,
      unit: widget.state.unit,
      barKg: widget.state.barWeightKg,
      onChanged: (kg) => widget.onSetWeightAt(li, setIndex, kg),
    );
  }

  Future<void> _logBodyweight(BuildContext context) async {
    final controller = TextEditingController();
    double? value;
    try {
      value = await showDialog<double>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Log body weight'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(suffixText: widget.state.unit.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, double.tryParse(controller.text)),
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (value == null) return;
    // Stored canonical in kg.
    widget.onLogBodyweight(
      widget.state.unit == Unit.kg ? value : lbToKg(value),
    );
  }
}

/// A slim "X / Y sets" progress strip under the app bar.
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final complete = total > 0 && done == total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                complete ? 'All sets logged' : '$done / $total sets',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: complete
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (complete) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 5,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.remaining,
    required this.total,
    required this.onDismiss,
  });

  final int remaining;
  final int total;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mm = (remaining ~/ 60).toString();
    final ss = (remaining % 60).toString().padLeft(2, '0');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$mm:$ss', style: theme.textTheme.headlineSmall),
              const SizedBox(width: 8),
              Text(
                'Rest',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onDismiss,
                child: const Text('Skip'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : (1 - remaining / total).clamp(0.0, 1.0),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiftCard extends StatelessWidget {
  const _LiftCard({
    required this.lift,
    required this.unit,
    required this.onCycle,
    required this.onEditWeight,
    required this.onEditSetWeight,
    required this.onAddSet,
    required this.onRemoveSet,
  });

  final ActiveLift lift;
  final Unit unit;
  final void Function(int setIndex, {required bool wasLogged}) onCycle;
  final VoidCallback onEditWeight;
  final void Function(int setIndex) onEditSetWeight;
  final VoidCallback onAddSet;
  final VoidCallback onRemoveSet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final top = lift.workingSets.isEmpty ? null : lift.workingSets.first;
    final topLabel = top == null
        ? ''
        : '${top.targetReps}×${formatWeight(displayWeight(top.weightKg, unit))}'
            ' ${unit.name}';

    // The next set to perform: the first one still unlogged (null once done).
    int? nextIndex;
    for (final s in lift.workingSets) {
      if (!s.logged) {
        nextIndex = s.index;
        break;
      }
    }
    final allDone = lift.workingSets.isNotEmpty && nextIndex == null;
    final allHit =
        lift.workingSets.every((s) => (s.actualReps ?? 0) >= s.targetReps);
    final semantic = SemanticColors.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onEditWeight,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (allDone) ...[
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: allHit ? semantic.success : semantic.failure,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(lift.name, style: theme.textTheme.titleMedium),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          topLabel,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: theme.colorScheme.primary),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ws in lift.workingSets)
                  _SetCell(
                    data: ws,
                    unit: unit,
                    isNext: ws.index == nextIndex,
                    onTap: () => onCycle(ws.index, wasLogged: ws.logged),
                    onEditWeight: () => onEditSetWeight(ws.index),
                  ),
                IconButton(
                  tooltip: 'Remove set',
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: lift.workingSets.length > 1 ? onRemoveSet : null,
                ),
                IconButton(
                  tooltip: 'Add set',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: onAddSet,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SetCell extends StatelessWidget {
  const _SetCell({
    required this.data,
    required this.unit,
    required this.isNext,
    required this.onTap,
    required this.onEditWeight,
  });

  final ActiveSet data;
  final Unit unit;

  /// The next set to perform in this lift — ringed so it's obvious what's up.
  final bool isNext;
  final VoidCallback onTap;

  /// Tapping the per-set weight opens the weight editor for just this set.
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = SemanticColors.of(context);
    final hit = (data.actualReps ?? 0) >= data.targetReps;

    final Color? bg;
    final Color? fg;
    if (!data.logged) {
      // The next set gets a faint brand tint so it stands out from the rest.
      bg = isNext ? scheme.primary.withValues(alpha: 0.14) : null;
      fg = null;
    } else if (hit) {
      // A completed set uses the brand colour (StrongLifts uses its own).
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else {
      // A short set stays red so a missed target reads at a glance.
      bg = semantic.failure;
      fg = semantic.onFailure;
    }

    // A logged set is a solid fill — match the ring to it so no grey outline
    // shows around a completed/missed circle. The next unlogged set gets the
    // primary ring; a plain unlogged set gets the neutral outline.
    final Border border;
    if (data.logged) {
      border = Border.all(color: bg!);
    } else if (isNext) {
      border = Border.all(color: scheme.primary, width: 2.5);
    } else {
      border = Border.all(color: scheme.outline);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              border: border,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${data.actualReps ?? data.targetReps}',
              style: TextStyle(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onEditWeight,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatWeight(displayWeight(data.weightKg, unit)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.edit,
                  size: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WarmupTab extends StatelessWidget {
  const _WarmupTab({
    required this.state,
    required this.doneWarmups,
    required this.onToggleWarmup,
  });

  final WorkoutState state;
  final Set<String> doneWarmups;
  final void Function(String key) onToggleWarmup;

  String _sideLabel(double weightKg) {
    final load = platesPerSide(
      displayWeight(weightKg, state.unit),
      displayWeight(state.barWeightKg, state.unit),
      platesFor(state.unit),
    );
    if (load.perSide.isEmpty && load.leftover == 0) return 'empty bar';
    return '${formatWeight(load.perSideTotal)} ${state.unit.name}/side';
  }

  String _repsLabel(int reps, double weightKg) =>
      '$reps×${formatWeight(displayWeight(weightKg, state.unit))} '
      '${state.unit.name}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        for (var li = 0; li < state.lifts.length; li++) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child:
                Text(state.lifts[li].name, style: theme.textTheme.titleMedium),
          ),
          if (state.lifts[li].warmups.isEmpty)
            Text(
              'No warmup needed — start with the working weight.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else ...[
            for (var wi = 0; wi < state.lifts[li].warmups.length; wi++)
              _WarmupRow(
                reps: state.lifts[li].warmups[wi].reps,
                label: _repsLabel(
                  state.lifts[li].warmups[wi].reps,
                  state.lifts[li].warmups[wi].weightKg,
                ),
                side: _sideLabel(state.lifts[li].warmups[wi].weightKg),
                done: doneWarmups.contains('$li-$wi'),
                onTap: () => onToggleWarmup('$li-$wi'),
              ),
            // The first working set as the final "go time" row.
            if (state.lifts[li].workingSets.isNotEmpty)
              _WarmupRow(
                reps: state.lifts[li].workingSets.first.targetReps,
                label: _repsLabel(
                  state.lifts[li].workingSets.first.targetReps,
                  state.lifts[li].workingSets.first.weightKg,
                ),
                side: _sideLabel(state.lifts[li].workingSets.first.weightKg),
                isWork: true,
              ),
          ],
        ],
      ],
    );
  }
}

/// A warmup ramp row. Warmup sets are tappable to check them off as you ramp
/// (visual only — warmups aren't counted toward progression and take little
/// rest). The final "go time" row ([isWork]) is a marker, not a checkbox.
class _WarmupRow extends StatelessWidget {
  const _WarmupRow({
    required this.reps,
    required this.label,
    required this.side,
    this.isWork = false,
    this.done = false,
    this.onTap,
  });

  final int reps;
  final String label;
  final String side;
  final bool isWork;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    final circleColor =
        (isWork || done) ? accent : theme.colorScheme.surfaceContainerHighest;

    final row = Opacity(
      opacity: done ? 0.55 : 1,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration:
                BoxDecoration(color: circleColor, shape: BoxShape.circle),
            child: done
                ? Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 22,
                  )
                : Text(
                    '$reps',
                    style: TextStyle(
                      color: isWork ? theme.colorScheme.onPrimary : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                decoration: done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Text(
            side,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isWork ? accent : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: row,
      ),
    );
  }
}

class _BodyweightRow extends StatelessWidget {
  const _BodyweightRow({
    required this.currentKg,
    required this.unit,
    required this.onTap,
  });

  final double? currentKg;
  final Unit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.monitor_weight_outlined),
        title: const Text('Body weight'),
        trailing: currentKg == null
            ? const Text('Log')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${formatWeight(displayWeight(currentKg!, unit))} '
                    '${unit.name}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
        onTap: onTap,
      ),
    );
  }
}
