import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';
import 'package:openlifts/features/settings/domain/settings_repository.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = openTestDb();
    repo = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  test('creates a default settings row on first access', () async {
    final s = await repo.get();
    expect(s.unit, Unit.kg);
    expect(s.barWeightKg, 20);
    expect(s.restTimerSeconds, 180);
  });

  test('save applies a partial update (round-trip)', () async {
    await repo.save(const SettingsCompanion(unit: Value(Unit.lb)));
    expect((await repo.get()).unit, Unit.lb);
  });

  test('resolveRestSeconds prefers the override, else global', () {
    expect(resolveRestSeconds(null, 180), 180);
    expect(resolveRestSeconds(90, 180), 90);
  });
}
