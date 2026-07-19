import 'package:openlifts/core/units/loadable.dart';

/// Immutable progression state for one lift: the working weight (anchor) and
/// the consecutive-failure streak.
class LiftState {
  const LiftState({
    required this.workingWeightKg,
    this.consecutiveFailures = 0,
  });

  final double workingWeightKg;
  final int consecutiveFailures;
}

/// The parts of an exercise's progression config the engine needs.
class LiftConfig {
  const LiftConfig({
    required this.incrementKg,
    this.deloadAfterFails = 3,
    this.deloadPercent = 10,
  });

  final double incrementKg;
  final int deloadAfterFails;
  final double deloadPercent;
}

/// Pure StrongLifts progression math — no Drift, no Riverpod, unit-tested in
/// isolation. All weights are kilograms.
class ProgressionEngine {
  const ProgressionEngine();

  /// Linear progression: apply a completed session's outcome to [state].
  ///
  /// All sets hit → add the increment, reset fails. Otherwise increment the
  /// fail streak; once it reaches [LiftConfig.deloadAfterFails], drop the
  /// weight by [LiftConfig.deloadPercent]% and reset the streak.
  LiftState applyLinear(
    LiftState state,
    LiftConfig config, {
    required bool allSetsHit,
  }) {
    if (allSetsHit) {
      return LiftState(
        workingWeightKg:
            roundToLoadableKg(state.workingWeightKg + config.incrementKg),
      );
    }
    final fails = state.consecutiveFailures + 1;
    if (fails >= config.deloadAfterFails) {
      return LiftState(
        workingWeightKg: roundToLoadableKg(
          state.workingWeightKg * (1 - config.deloadPercent / 100),
        ),
      );
    }
    return LiftState(
      workingWeightKg: state.workingWeightKg,
      consecutiveFailures: fails,
    );
  }

  /// Percentage style (Madcow): a completed top set becomes the new anchor.
  double newAnchorFromTopSet(double topSetWeightKg) =>
      roundToLoadableKg(topSetWeightKg);

  /// Percentage style: advance the anchor by [weeklyPercent]% for the week.
  double advanceWeekly(double anchorKg, double weeklyPercent) =>
      roundToLoadableKg(anchorKg * (1 + weeklyPercent / 100));
}
