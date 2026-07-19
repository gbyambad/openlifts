import 'package:flutter/services.dart' show rootBundle;
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/backup/data/backup_repository_impl.dart';
import 'package:openlifts/features/backup/domain/backup_repository.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_providers.g.dart';

@riverpod
BackupRepository backupRepository(Ref ref) =>
    DriftBackupRepository(ref.watch(appDatabaseProvider));

/// Orchestrates export/restore for the UI: serializing, validating, and
/// restoring (loading the built-in seed from bundled assets).
///
/// Kept alive: an action-only controller reached via `ref.read(...notifier)`
/// with no listener. Auto-dispose would tear it down before export/restore
/// finishes its async work, throwing `UnmountedRefException` (same footgun
/// fixed on `SettingsController`).
@Riverpod(keepAlive: true)
class BackupController extends _$BackupController {
  @override
  void build() {}

  Future<String> exportJson() =>
      ref.read(backupRepositoryProvider).exportToJson();

  void validate(String json) =>
      ref.read(backupRepositoryProvider).validate(json);

  Future<void> restore(String json) async {
    final [exercisesSeed, programsSeed] = await Future.wait([
      rootBundle.loadString('assets/seed/exercises.json'),
      rootBundle.loadString('assets/seed/programs.json'),
    ]);
    await ref.read(backupRepositoryProvider).restoreFromJson(
          json,
          exercisesSeed: exercisesSeed,
          programsSeed: programsSeed,
        );
    // Reactive Drift streams refresh themselves; these snapshot views don't.
    ref
      ..invalidate(todayProvider)
      ..invalidate(programsViewProvider);
  }
}
