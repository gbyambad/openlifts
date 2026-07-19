import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/exercises/application/exercises_providers.dart';
import 'package:openlifts/features/sessions/application/session_providers.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'history_view.g.dart';

/// The history list plus the unit its summaries are shown in.
class HistoryData {
  const HistoryData({required this.entries, required this.unit});

  final List<HistoryEntry> entries;
  final Unit unit;
}

@riverpod
Future<HistoryData> historyView(Ref ref) async {
  final entries = await ref.watch(historyProvider.future);
  final settings = await ref.watch(settingsProvider.future);
  return HistoryData(entries: entries, unit: settings.unit);
}

/// One exercise's work in a past session (name + a "reps · weight" summary).
class SessionExercise {
  const SessionExercise({required this.name, required this.summary});

  final String name;
  final String summary;
}

/// The exercises logged in a completed session, loaded lazily when a history
/// row is expanded.
@riverpod
Future<List<SessionExercise>> sessionExercises(Ref ref, int sessionId) async {
  final logs = await ref.watch(sessionRepositoryProvider).setsFor(sessionId);
  final settings = await ref.watch(settingsRepositoryProvider).get();
  final exerciseRepo = ref.watch(exerciseRepositoryProvider);

  final order = <String>[];
  final byExercise = <String, List<int>>{};
  final topKg = <String, double>{};
  for (final log in logs) {
    if (!byExercise.containsKey(log.exerciseId)) order.add(log.exerciseId);
    byExercise.putIfAbsent(log.exerciseId, () => []).add(log.actualReps ?? 0);
    topKg[log.exerciseId] = (topKg[log.exerciseId] ?? 0) > log.weightKg
        ? topKg[log.exerciseId]!
        : log.weightKg;
  }

  final exercisesById = await exerciseRepo.findByIds(order);
  final result = <SessionExercise>[];
  for (final id in order) {
    final ex = exercisesById[id];
    final reps = byExercise[id]!.join('·');
    result.add(
      SessionExercise(
        name: ex?.name ?? id,
        summary: '$reps · ${weightLabel(topKg[id]!, settings.unit)}',
      ),
    );
  }
  return result;
}
