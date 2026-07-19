import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/sessions/data/session_repository_impl.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_providers.g.dart';

@riverpod
SessionRepository sessionRepository(Ref ref) =>
    DriftSessionRepository(ref.watch(appDatabaseProvider));

/// Per-set progress points, oldest-first.
final liftSeriesProvider = StreamProvider<List<LiftSeriesPoint>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchLiftSeries(),
);

/// Completed workouts, newest-first, for the history list.
final historyProvider = StreamProvider<List<HistoryEntry>>(
  (ref) => ref.watch(sessionRepositoryProvider).watchHistory(),
);
