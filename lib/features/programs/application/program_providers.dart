import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/programs/data/program_repository_impl.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'program_providers.g.dart';

@riverpod
ProgramRepository programRepository(Ref ref) =>
    DriftProgramRepository(ref.watch(appDatabaseProvider));
