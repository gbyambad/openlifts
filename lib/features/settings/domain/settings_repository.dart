import 'package:openlifts/core/database/app_database.dart';

/// App-preferences store. Returns the Drift [Setting] row.
abstract interface class SettingsRepository {
  /// The settings row, creating the default on first access.
  Future<Setting> get();

  /// Reactive settings — emits on every change.
  Stream<Setting> watch();

  /// Apply a partial update to the settings row.
  Future<void> save(SettingsCompanion changes);
}

/// Rest seconds to use: the exercise's override, else the global default.
int resolveRestSeconds(int? exerciseOverride, int globalDefault) =>
    exerciseOverride ?? globalDefault;
