import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/theme/semantic_colors.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/sessions/application/active_workout_controller.dart';
import 'package:openlifts/features/workout/domain/plate_math.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';
import 'package:openlifts/shared/widgets/confirm_dialog.dart';
import 'package:openlifts/shared/widgets/plate_bar.dart';

/// Presentational active-workout UI. Pure (no providers/DB) so it is
/// widget-testable directly with a fixed [WorkoutState] and callbacks.
class ActiveWorkoutView extends StatefulWidget {
  const ActiveWorkoutView({
    required this.state,
    required this.onCycleSet,
    required this.onSetWeight,
    required this.onSetWeightAt,
    required this.onSetWeightFrom,
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

  /// Set one set's weight and cascade it to every later set — the "recalculate
  /// the following sets" action for non-straight schemes.
  final void Function(int liftIndex, int setIndex, double weightKg)
      onSetWeightFrom;
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

  void _toggleWarmup(String key) {
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      if (!_doneWarmups.add(key)) _doneWarmups.remove(key);
    });
    // When the lift just checked off has all its warmups done, move on to the
    // working sets. Per-lift, not day-wide: later lifts warm up as you reach
    // them, so gating on every lift's warmups would strand you here.
    final li = int.parse(key.split('-').first);
    final warmups = widget.state.lifts[li].warmups;
    final liftAllDone = warmups.isNotEmpty &&
        List.generate(warmups.length, (wi) => '$li-$wi')
            .every(_doneWarmups.contains);
    if (liftAllDone && _tabs.index != 0) _tabs.animateTo(0);
  }

  /// Whether the next not-yet-finished lift after [afterLift] still has a
  /// warmup to check off. Only that lift matters: a next lift with no warmups
  /// should drop you straight onto its working sets, not an empty Warmup tab.
  bool _nextLiftNeedsWarmup(int afterLift) {
    for (var li = afterLift + 1; li < widget.state.lifts.length; li++) {
      final lift = widget.state.lifts[li];
      final finished = lift.workingSets.isNotEmpty &&
          lift.workingSets.every((s) => s.logged);
      if (finished) continue; // skip lifts already done (e.g. logged early)
      for (var wi = 0; wi < lift.warmups.length; wi++) {
        if (!_doneWarmups.contains('$li-$wi')) return true;
      }
      return false; // the next lift to work has no pending warmup
    }
    return false;
  }

  static bool _sameWarmups(List<WarmupSet> a, List<WarmupSet> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].weightKg != b[i].weightKg || a[i].reps != b[i].reps) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(ActiveWorkoutView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lifts = widget.state.lifts;
    final old = oldWidget.state.lifts;

    // A lift's warmups were recomputed (e.g. a working-weight change reshaped
    // the ramp): drop that lift's stale check-marks so they don't linger as
    // "done" against weights the user never warmed up with. Safe to mutate
    // without setState — a rebuild is already underway.
    for (var li = 0; li < lifts.length; li++) {
      final oldWarmups =
          li < old.length ? old[li].warmups : const <WarmupSet>[];
      if (!_sameWarmups(oldWarmups, lifts[li].warmups)) {
        _doneWarmups.removeWhere((k) => k.startsWith('$li-'));
      }
    }

    // When a lift's working sets just became fully logged and a later lift
    // still needs warming up, nudge over to the Warmup tab.
    for (var li = 0; li < lifts.length; li++) {
      final done = lifts[li].workingSets.isNotEmpty &&
          lifts[li].workingSets.every((s) => s.logged);
      final wasDone = li < old.length &&
          old[li].workingSets.isNotEmpty &&
          old[li].workingSets.every((s) => s.logged);
      if (done && !wasDone && _nextLiftNeedsWarmup(li)) {
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
                    Flexible(
                      child: Text(
                        state.dayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
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
            tabController: _tabs,
            onCycleSet: widget.onCycleSet,
            onSetWeight: widget.onSetWeight,
            onSetWeightAt: widget.onSetWeightAt,
            onSetWeightFrom: widget.onSetWeightFrom,
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
    required this.tabController,
    required this.onCycleSet,
    required this.onSetWeight,
    required this.onSetWeightAt,
    required this.onSetWeightFrom,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onLogBodyweight,
  });

  final WorkoutState state;
  final TabController tabController;
  final void Function(int, int) onCycleSet;
  final void Function(int, double) onSetWeight;
  final void Function(int, int, double) onSetWeightAt;
  final void Function(int, int, double) onSetWeightFrom;
  final void Function(int) onAddSet;
  final void Function(int) onRemoveSet;
  final void Function(double) onLogBodyweight;

  @override
  State<_WorkoutTab> createState() => _WorkoutTabState();
}

class _WorkoutTabState extends State<_WorkoutTab> {
  Timer? _timer;
  int _restRemaining = 0;

  final _scroll = ScrollController();
  // One key per lift card, so the current exercise can be scrolled into view.
  final _cardKeys = <GlobalKey>[];
  // Eagerly set from the initial state; a lazy `late` initializer would first
  // evaluate inside didUpdateWidget (after widget.state already advanced),
  // hiding the very change we compare against.
  late int _currentLift;

  @override
  void initState() {
    super.initState();
    _currentLift = _firstUnfinishedLift();
    widget.tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    _scroll.dispose();
    _timer?.cancel();
    super.dispose();
  }

  /// The lift the user is on: the first with an unlogged set (last if done).
  int _firstUnfinishedLift() {
    final lifts = widget.state.lifts;
    for (var i = 0; i < lifts.length; i++) {
      final l = lifts[i];
      final done =
          l.workingSets.isNotEmpty && l.workingSets.every((s) => s.logged);
      if (!done) return i;
    }
    return lifts.isEmpty ? 0 : lifts.length - 1;
  }

  void _onTabChanged() {
    // Back on the Workout tab (e.g. after warming up the next lift) — bring the
    // current exercise into view.
    if (!widget.tabController.indexIsChanging &&
        widget.tabController.index == 0) {
      _scrollToCurrentLift();
    }
  }

  void _scrollToCurrentLift() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentLift >= _cardKeys.length) return;
      final ctx = _cardKeys[_currentLift].currentContext;
      if (ctx == null) return;
      unawaited(
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.05, // pin near the top, leaving a sliver of the prior
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ),
      );
    });
  }

  @override
  void didUpdateWidget(_WorkoutTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = _firstUnfinishedLift();
    if (current != _currentLift) {
      _currentLift = current; // a lift was completed -> focus the next one
      _scrollToCurrentLift();
    }
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
    if (_cardKeys.length != state.lifts.length) {
      _cardKeys
        ..clear()
        ..addAll([for (var i = 0; i < state.lifts.length; i++) GlobalKey()]);
    }
    return Column(
      children: [
        _ProgressHeader(done: doneSets, total: allSets.length),
        Expanded(
          // A SingleChildScrollView (not ListView) so every lift card is laid
          // out — a lazy ListView drops off-screen cards, leaving their keys
          // context-less and unreachable by Scrollable.ensureVisible. Workouts
          // have only a handful of lifts, so eager layout costs nothing.
          child: SingleChildScrollView(
            key: const Key('activeWorkoutList'),
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: Column(
              children: [
                for (var li = 0; li < state.lifts.length; li++)
                  _LiftCard(
                    key: _cardKeys[li],
                    lift: state.lifts[li],
                    unit: state.unit,
                    isCurrent: li == _currentLift,
                    onCycle: (si, {required wasLogged}) {
                      unawaited(HapticFeedback.selectionClick());
                      widget.onCycleSet(li, si);
                      if (!wasLogged) _startRest();
                    },
                    onEditWeight: () =>
                        _editWeight(context, li, state.lifts[li]),
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
  ) async {
    final before =
        lift.workingSets.firstWhere((ws) => ws.index == setIndex).weightKg;
    await showWeightEditor(
      context,
      title: '${lift.name} — set ${setIndex + 1} weight',
      initialKg: before,
      unit: widget.state.unit,
      barKg: widget.state.barWeightKg,
      onChanged: (kg) => widget.onSetWeightAt(li, setIndex, kg),
    );
    if (!context.mounted) return;

    // Read the committed weight back from the now-updated state, then offer to
    // carry the change into the later sets (StrongLifts keeps earlier ones).
    final updated = widget.state.lifts[li];
    final now =
        updated.workingSets.firstWhere((ws) => ws.index == setIndex).weightKg;
    if (now == before) return; // nothing changed

    // Which later sets a recalc would actually move (straight/back-off just
    // copy the weight; a top-set or ramp edit re-derives them proportionally).
    final recalced = updated.weightsAfterEditingFrom(setIndex, now);
    final changedFollowing = [
      for (final ws in updated.workingSets)
        if (ws.index > setIndex &&
            ws.index < recalced.length &&
            recalced[ws.index] != ws.weightKg)
          ws.index,
    ];
    if (changedFollowing.isEmpty) return; // no later set moves

    final unit = widget.state.unit;
    final isCopy = changedFollowing.every((i) => recalced[i] == now);
    final cascade = await showConfirmDialog(
      context,
      title: isCopy
          ? 'Update the following sets?'
          : 'Recalculate the following sets?',
      message: isCopy
          ? 'Set every set after this one to ${weightLabel(now, unit)} too?'
          : 'Recalculate the sets after this one from '
              '${weightLabel(now, unit)}, keeping their back-off/ramp pattern?',
      cancelLabel: 'Only this set',
      confirmLabel: isCopy ? 'Update following' : 'Recalculate',
    );
    if (cascade ?? false) widget.onSetWeightFrom(li, setIndex, now);
  }

  Future<void> _logBodyweight(BuildContext context) async {
    final value = await showDialog<double>(
      context: context,
      builder: (_) => _BodyweightDialog(unit: widget.state.unit),
    );
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

/// Body-weight entry dialog. Owns its [TextEditingController] so it lives
/// through the dialog's close animation — disposing it in the caller right
/// after `showDialog` returned tore it down mid-animation and threw
/// "used after disposed". Save stays disabled until the input is a valid
/// positive number, so it can't silently no-op.
class _BodyweightDialog extends StatefulWidget {
  const _BodyweightDialog({required this.unit});

  final Unit unit;

  @override
  State<_BodyweightDialog> createState() => _BodyweightDialogState();
}

class _BodyweightDialogState extends State<_BodyweightDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _parsed {
    final v = double.tryParse(_controller.text.trim());
    return (v != null && v > 0) ? v : null;
  }

  void _save() {
    final v = _parsed;
    if (v != null) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Log body weight'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(suffixText: widget.unit.name),
        onChanged: (_) => setState(() {}), // re-evaluate the Save button
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _parsed == null ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _LiftCard extends StatelessWidget {
  const _LiftCard({
    required this.lift,
    required this.unit,
    required this.isCurrent,
    required this.onCycle,
    required this.onEditWeight,
    required this.onEditSetWeight,
    required this.onAddSet,
    required this.onRemoveSet,
    super.key,
  });

  final ActiveLift lift;
  final Unit unit;

  /// Whether this is the lift the user is on — only it shows the pulsing cursor
  /// on its next set, so there's a single "do this now" marker per workout.
  final bool isCurrent;
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
            // Two separate tap targets: the name (+ info icon) opens the
            // how-to sheet; the weight (+ chevron) opens the weight editor.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: InkWell(
                    onTap: () => _showExerciseInfo(context, lift),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (allDone) ...[
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color:
                                  allHit ? semantic.success : semantic.failure,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              lift.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.info_outline,
                            size: 17,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: onEditWeight,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final ws in lift.workingSets)
                  _SetCell(
                    // Keyed so there's a single testable "do this now" marker.
                    key: isCurrent && ws.index == nextIndex
                        ? const Key('cursorSet')
                        : null,
                    data: ws,
                    unit: unit,
                    isCursor: isCurrent && ws.index == nextIndex,
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

/// Shows an exercise's how-to steps in a bottom sheet, so form cues are one tap
/// away mid-workout without leaving the session (and losing the rest timer).
Future<void> _showExerciseInfo(BuildContext context, ActiveLift lift) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lift.name, style: theme.textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                'How to perform',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 14),
              if (lift.instructions.isEmpty)
                Text(
                  'No instructions for this exercise yet.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (var i = 0; i < lift.instructions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${i + 1}.  ',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            lift.instructions[i],
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}

class _SetCell extends StatelessWidget {
  const _SetCell({
    required this.data,
    required this.unit,
    required this.isCursor,
    required this.onTap,
    required this.onEditWeight,
    super.key,
  });

  final ActiveSet data;
  final Unit unit;

  /// The single "do this now" set across the whole workout — it gently pulses
  /// (StrongLifts-style) so the next thing to do is obvious as the list moves.
  final bool isCursor;
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
      // The cursor set gets a faint brand tint so it stands out from the rest.
      bg = isCursor ? scheme.primary.withValues(alpha: 0.14) : null;
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
    // shows around a completed/missed circle. The cursor set gets a thin brand
    // ring (the pulse does the attention-grabbing); others a neutral outline.
    final Border border;
    if (data.logged) {
      border = Border.all(color: bg!);
    } else if (isCursor) {
      border = Border.all(color: scheme.primary, width: 1.5);
    } else {
      border = Border.all(color: scheme.outline);
    }

    Widget circle = Container(
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
    );
    if (isCursor) {
      circle = _HeartbeatPulse(color: scheme.primary, child: circle);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: circle,
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

/// A minimal, repeating "heartbeat" for the active set: a gentle ~4% scale
/// breath, no glow (the thin ring + faint tint already mark the set). Honours
/// reduced-motion (`MediaQuery.disableAnimations`) by rendering [child] static.
///
/// Dial the feel with [_pulseScale] (breath depth) and the controller duration
/// (breath speed).
class _HeartbeatPulse extends StatefulWidget {
  const _HeartbeatPulse({required this.color, required this.child});

  final Color color;
  final Widget child;

  static const _pulseScale = 0.04;

  @override
  State<_HeartbeatPulse> createState() => _HeartbeatPulseState();
}

class _HeartbeatPulseState extends State<_HeartbeatPulse>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller?.dispose();
      _controller = null;
    } else if (_controller == null) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1100),
      );
      unawaited(controller.repeat(reverse: true));
      _controller = controller;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return widget.child;
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(controller.value);
        return Transform.scale(
          scale: 1 + _HeartbeatPulse._pulseScale * t,
          child: child,
        );
      },
      child: widget.child,
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
