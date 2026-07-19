import 'package:drift/drift.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/settings/domain/settings_repository.dart';

/// Drift-backed [SettingsRepository] over the single-row settings table.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);

  final AppDatabase _db;

  Future<void> _ensureDefault() async {
    await _db.into(_db.settings).insert(
          SettingsCompanion.insert(
            id: const Value(1),
            unit: Unit.kg,
            barWeightKg: 20,
            restTimerSeconds: 180,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<Setting> get() async {
    await _ensureDefault();
    return (_db.select(_db.settings)..where((t) => t.id.equals(1))).getSingle();
  }

  @override
  Stream<Setting> watch() async* {
    await _ensureDefault();
    yield* (_db.select(_db.settings)..where((t) => t.id.equals(1)))
        .watchSingle();
  }

  @override
  Future<void> save(SettingsCompanion changes) async {
    await _ensureDefault();
    await (_db.update(_db.settings)..where((t) => t.id.equals(1)))
        .write(changes);
  }
}
