import 'package:drift/drift.dart' show Value;
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/units/loadable.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/programs/application/program_weights.dart';
import 'package:openlifts/features/progression/application/progression_providers.dart';
import 'package:openlifts/features/progression/domain/layoff_deload.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_back.g.dart';

/// A suggested welcome-back deload after a training layoff.
class WelcomeBack {
  const WelcomeBack({required this.daysAway, required this.suggestedPercent});

  final int daysAway;
  final int suggestedPercent;
}

/// Suggests easing back in with lighter weights when you return after a break.
/// Null when there's no active program, no training history, the gap is short,
/// or the current layoff was already handled (applied or dismissed).
@riverpod
Future<WelcomeBack?> welcomeBack(Ref ref) async {
  final settings = await ref.watch(settingsRepositoryProvider).get();
  if (settings.activeProgramId == null) return null;

  final history =
      await ref.watch(sessionRepositoryProvider).watchHistory().first;
  if (history.isEmpty) return null; // no completed workouts yet
  final lastWorkout = history.first.date; // newest-first

  // Already applied or dismissed a deload since that last workout.
  final handled = settings.deloadHandledAt;
  if (handled != null && !handled.isBefore(lastWorkout)) return null;

  final daysAway = DateTime.now().difference(lastWorkout).inDays;
  final percent = layoffDeloadPercent(daysAway);
  if (percent == 0) return null;

  // Nothing to deload if no working weights are recorded.
  final progress = await ref.watch(liftProgressRepositoryProvider).getAll();
  if (progress.isEmpty) return null;

  return WelcomeBack(daysAway: daysAway, suggestedPercent: percent);
}

/// Applies or dismisses the welcome-back deload.
///
/// Kept alive: an action-only controller reached via `ref.read(...notifier)`
/// with no listener, so auto-dispose would tear it down mid-write.
@Riverpod(keepAlive: true)
class WelcomeBackController extends _$WelcomeBackController {
  @override
  void build() {}

  /// Reduces every recorded lift's working weight by [percent], rounds to a
  /// loadable weight, resets failure streaks, and marks the layoff handled.
  Future<void> applyDeload(int percent) async {
    final repo = ref.read(liftProgressRepositoryProvider);
    final now = DateTime.now();
    final factor = 1 - percent / 100;
    for (final p in await repo.getAll()) {
      await repo.upsert(
        exerciseId: p.exerciseId,
        workingWeightKg: roundToLoadableKg(p.workingWeightKg * factor),
        updatedAt: now,
      );
    }
    await _markHandled(now);
  }

  /// Keeps the current weights but marks the layoff handled so it isn't
  /// prompted again until the next break.
  Future<void> dismiss() => _markHandled(DateTime.now());

  Future<void> _markHandled(DateTime at) async {
    await ref
        .read(settingsRepositoryProvider)
        .save(SettingsCompanion(deloadHandledAt: Value(at)));
    ref
      ..invalidate(welcomeBackProvider)
      ..invalidate(todayProvider)
      ..invalidate(programWeightsProvider);
  }
}
