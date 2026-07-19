import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/bodyweight/data/bodyweight_repository_impl.dart';
import 'package:openlifts/features/bodyweight/domain/bodyweight_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bodyweight_providers.g.dart';

@riverpod
BodyweightRepository bodyweightRepository(Ref ref) =>
    DriftBodyweightRepository(ref.watch(appDatabaseProvider));

/// Bodyweight series, oldest-first.
final bodyweightSeriesProvider = StreamProvider<List<BodyweightEntry>>(
  (ref) => ref.watch(bodyweightRepositoryProvider).watchSeries(),
);
