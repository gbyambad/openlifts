import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/bodyweight/application/bodyweight_providers.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/domain/set_group_resolver.dart';
import 'package:openlifts/features/progression/application/progression_providers.dart';
import 'package:openlifts/features/progression/domain/default_anchor.dart';
import 'package:openlifts/features/progression/domain/progression_engine.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:openlifts/features/workout/domain/warmup_calculator.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_workout_controller.g.dart';

/// One working set in an active workout.
class ActiveSet {
  const ActiveSet({
    required this.index,
    required this.weightKg,
    required this.targetReps,
    this.actualReps,
  });

  final int index;
  final double weightKg;
  final int targetReps;
  final int? actualReps;

  bool get logged => actualReps != null;

  ActiveSet copyWith({int? actualReps}) => ActiveSet(
        index: index,
        weightKg: weightKg,
        targetReps: targetReps,
        actualReps: actualReps ?? this.actualReps,
      );
}

/// One lift in an active workout: its resolved sets + progression config.
class ActiveLift {
  const ActiveLift({
    required this.exerciseId,
    required this.name,
    required this.anchorKg,
    required this.warmups,
    required this.workingSets,
    required this.incrementKg,
    required this.deloadAfterFails,
    required this.deloadPercent,
    this.setGroups = const [],
    this.startsLoaded = false,
  });

  final String exerciseId;
  final String name;
  final double anchorKg;
  final List<WarmupSet> warmups;
  final List<ActiveSet> workingSets;
  final double incrementKg;
  final int deloadAfterFails;
  final double deloadPercent;

  /// The prescription's set-group specs, kept so a mid-workout weight change
  /// can re-resolve every set from the new anchor.
  final List<SetGroupSpec> setGroups;
  final bool startsLoaded;

  ActiveLift copyWith({
    double? anchorKg,
    List<WarmupSet>? warmups,
    List<ActiveSet>? workingSets,
  }) =>
      ActiveLift(
        exerciseId: exerciseId,
        name: name,
        anchorKg: anchorKg ?? this.anchorKg,
        warmups: warmups ?? this.warmups,
        workingSets: workingSets ?? this.workingSets,
        incrementKg: incrementKg,
        deloadAfterFails: deloadAfterFails,
        deloadPercent: deloadPercent,
        setGroups: setGroups,
        startsLoaded: startsLoaded,
      );
}

class WorkoutState {
  const WorkoutState({
    required this.dayId,
    required this.dayName,
    required this.unit,
    required this.lifts,
    required this.isLinear,
    this.barWeightKg = 20,
    this.restSeconds = 180,
    this.days = const [],
    this.bodyweightKg,
  });

  final String dayId;
  final String dayName;
  final Unit unit;
  final List<ActiveLift> lifts;
  final bool isLinear;
  final double barWeightKg;
  final int restSeconds;

  /// Every workout day in the program, for the "switch workout" control.
  final List<({String id, String name})> days;

  /// The most recently logged bodyweight (kg), or null if none yet.
  final double? bodyweightKg;

  WorkoutState copyWith({List<ActiveLift>? lifts, double? bodyweightKg}) =>
      WorkoutState(
        dayId: dayId,
        dayName: dayName,
        unit: unit,
        lifts: lifts ?? this.lifts,
        isLinear: isLinear,
        barWeightKg: barWeightKg,
        restSeconds: restSeconds,
        days: days,
        bodyweightKg: bodyweightKg ?? this.bodyweightKg,
      );
}

/// Drives an active workout: resolves the day's sets, logs reps, and on finish
/// writes the session + set logs and applies progression to each lift.
@riverpod
class ActiveWorkoutController extends _$ActiveWorkoutController {
  @override
  Future<WorkoutState> build(String dayId) async {
    final settings = await ref.watch(settingsRepositoryProvider).get();
    final programId = settings.activeProgramId;
    if (programId == null) {
      throw StateError('No active program');
    }
    final tree = await ref.watch(programRepositoryProvider).loadTree(programId);
    final dayNode = tree!.days.firstWhere((d) => d.day.id == dayId);
    final progress = ref.watch(liftProgressRepositoryProvider);
    final progressById = await progress.getMany([
      for (final p in dayNode.prescriptions) p.exercise.id,
    ]);

    final lifts = <ActiveLift>[];
    for (final p in dayNode.prescriptions) {
      final ex = p.exercise;
      final anchor = defaultAnchorKg(
        workingWeightKg: progressById[ex.id]?.workingWeightKg,
        startsLoaded: ex.startsLoaded,
      );

      final specs = [
        for (final g in p.setGroups)
          SetGroupSpec(
            sets: g.sets,
            reps: g.reps,
            weightRule: g.weightRule,
            weightParam: g.weightParam,
          ),
      ];

      lifts.add(
        ActiveLift(
          exerciseId: ex.id,
          name: ex.name,
          anchorKg: anchor,
          warmups: computeWarmups(anchor, startsLoaded: ex.startsLoaded),
          workingSets: _resolveSets(specs, anchor),
          incrementKg: ex.incrementKg,
          deloadAfterFails: ex.deloadAfterFails,
          deloadPercent: ex.deloadPercent,
          setGroups: specs,
          startsLoaded: ex.startsLoaded,
        ),
      );
    }

    final series = await ref.watch(bodyweightRepositoryProvider).series();

    return WorkoutState(
      dayId: dayId,
      dayName: dayNode.day.name,
      unit: settings.unit,
      lifts: lifts,
      isLinear: tree.program.progressionStyle == ProgressionStyle.linear,
      barWeightKg: settings.barWeightKg,
      restSeconds: settings.restTimerSeconds,
      days: [for (final d in tree.days) (id: d.day.id, name: d.day.name)],
      // series() is oldest-first, so the last entry is the current bodyweight.
      bodyweightKg: series.isEmpty ? null : series.last.weightKg,
    );
  }

  /// Log today's bodyweight and reflect it immediately in the row.
  Future<void> logBodyweight(double weightKg) async {
    await ref.read(bodyweightRepositoryProvider).add(DateTime.now(), weightKg);
    final s = state.value;
    if (s != null) state = AsyncData(s.copyWith(bodyweightKg: weightKg));
  }

  static List<ActiveSet> _resolveSets(
    List<SetGroupSpec> specs,
    double anchor, {
    List<ActiveSet> keepRepsFrom = const [],
  }) {
    final sets = <ActiveSet>[];
    var i = 0;
    for (final spec in specs) {
      for (final r in resolveSetGroup(anchor, spec)) {
        final prior = i < keepRepsFrom.length ? keepRepsFrom[i] : null;
        sets.add(
          ActiveSet(
            index: i,
            weightKg: r.weightKg,
            targetReps: r.reps,
            actualReps: prior?.actualReps,
          ),
        );
        i++;
      }
    }
    return sets;
  }

  void _replaceLift(int liftIndex, ActiveLift lift) {
    final s = state.value;
    if (s == null) return;
    state = AsyncData(
      s.copyWith(
        lifts: [
          for (var i = 0; i < s.lifts.length; i++)
            if (i == liftIndex) lift else s.lifts[i],
        ],
      ),
    );
  }

  /// Log [reps] for a working set.
  void logReps(int liftIndex, int setIndex, int reps) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    _replaceLift(
      liftIndex,
      lift.copyWith(
        workingSets: [
          for (final ws in lift.workingSets)
            if (ws.index == setIndex) ws.copyWith(actualReps: reps) else ws,
        ],
      ),
    );
  }

  /// Tapping a set cycles its logged reps: unlogged → target reps → target−1 →
  /// … → 0 → unlogged again. Mirrors StrongLifts' set logging.
  void cycleSet(int liftIndex, int setIndex) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    _replaceLift(
      liftIndex,
      lift.copyWith(
        workingSets: [
          for (final ws in lift.workingSets)
            if (ws.index == setIndex) _cycled(ws) else ws,
        ],
      ),
    );
  }

  static ActiveSet _cycled(ActiveSet ws) {
    final next = switch (ws.actualReps) {
      null => ws.targetReps, // first tap: full reps
      0 => null, // past zero: back to unlogged
      final r => r - 1, // decrement toward zero
    };
    return ActiveSet(
      index: ws.index,
      weightKg: ws.weightKg,
      targetReps: ws.targetReps,
      actualReps: next,
    );
  }

  /// Change a lift's working weight mid-session, re-resolving every set (top
  /// set + back-offs) and its warmup ramp from the new anchor.
  void setLiftWeight(int liftIndex, double anchorKg) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    final anchor = anchorKg < 0 ? 0.0 : anchorKg;
    final specs = lift.setGroups.isEmpty
        ? [
            SetGroupSpec(
              sets: lift.workingSets.length,
              reps: 5,
              weightRule: WeightRule.straight,
            ),
          ]
        : lift.setGroups;
    _replaceLift(
      liftIndex,
      lift.copyWith(
        anchorKg: anchor,
        warmups: computeWarmups(anchor, startsLoaded: lift.startsLoaded),
        workingSets:
            _resolveSets(specs, anchor, keepRepsFrom: lift.workingSets),
      ),
    );
  }

  /// Override a single working set's weight, leaving the other sets and the
  /// lift's anchor untouched. Lets any set (top set or a back-off) be dialled
  /// individually mid-workout; the per-set weight carries into the set log.
  void setSetWeight(int liftIndex, int setIndex, double weightKg) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    final weight = weightKg < 0 ? 0.0 : weightKg;
    _replaceLift(
      liftIndex,
      lift.copyWith(
        workingSets: [
          for (final ws in lift.workingSets)
            if (ws.index == setIndex)
              ActiveSet(
                index: ws.index,
                weightKg: weight,
                targetReps: ws.targetReps,
                actualReps: ws.actualReps,
              )
            else
              ws,
        ],
      ),
    );
  }

  /// Append a working set matching the last one's weight and reps.
  void addSet(int liftIndex) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    final last = lift.workingSets.isEmpty ? null : lift.workingSets.last;
    _replaceLift(
      liftIndex,
      lift.copyWith(
        workingSets: [
          ...lift.workingSets,
          ActiveSet(
            index: lift.workingSets.length,
            weightKg: last?.weightKg ?? lift.anchorKg,
            targetReps: last?.targetReps ?? 5,
          ),
        ],
      ),
    );
  }

  /// Drop the last working set (keeps at least one).
  void removeSet(int liftIndex) {
    final s = state.value;
    if (s == null) return;
    final lift = s.lifts[liftIndex];
    if (lift.workingSets.length <= 1) return;
    _replaceLift(
      liftIndex,
      lift.copyWith(
        workingSets: lift.workingSets.sublist(0, lift.workingSets.length - 1),
      ),
    );
  }

  /// Persist the workout and apply progression to each lift.
  Future<void> finish() async {
    final s = state.value;
    if (s == null) return;
    final db = ref.read(appDatabaseProvider);
    final sessions = ref.read(sessionRepositoryProvider);
    final progress = ref.read(liftProgressRepositoryProvider);
    const engine = ProgressionEngine();
    final now = DateTime.now();

    await db.transaction(() async {
      final sessionId = await sessions.startSession(s.dayId, now);
      for (final lift in s.lifts) {
        for (final ws in lift.workingSets) {
          await sessions.logSet(
            sessionId: sessionId,
            exerciseId: lift.exerciseId,
            setIndex: ws.index,
            weightKg: ws.weightKg,
            targetReps: ws.targetReps,
            actualReps: ws.actualReps,
          );
        }
        // Linear progression only; percentage (Madcow) is applied elsewhere.
        if (s.isLinear) {
          final allHit = lift.workingSets
              .every((ws) => (ws.actualReps ?? 0) >= ws.targetReps);
          final lp = await progress.get(lift.exerciseId);
          final current = LiftState(
            // The in-session anchor is what was actually worked (mid-workout
            // weight edits carry into progression).
            workingWeightKg: lift.anchorKg,
            consecutiveFailures: lp?.consecutiveFailures ?? 0,
          );
          final next = engine.applyLinear(
            current,
            LiftConfig(
              incrementKg: lift.incrementKg,
              deloadAfterFails: lift.deloadAfterFails,
              deloadPercent: lift.deloadPercent,
            ),
            allSetsHit: allHit,
          );
          await progress.upsert(
            exerciseId: lift.exerciseId,
            workingWeightKg: next.workingWeightKg,
            consecutiveFailures: next.consecutiveFailures,
            updatedAt: now,
          );
        }
      }
      await sessions.completeSession(sessionId, now);
    });
  }
}
