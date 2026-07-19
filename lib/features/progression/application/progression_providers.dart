import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/progression/data/lift_progress_repository_impl.dart';
import 'package:openlifts/features/progression/domain/lift_progress_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progression_providers.g.dart';

@riverpod
LiftProgressRepository liftProgressRepository(Ref ref) =>
    DriftLiftProgressRepository(ref.watch(appDatabaseProvider));
