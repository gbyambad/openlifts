import 'package:drift/native.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';

void main() {
  test('setUnit and setRest persist', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final ctrl = container.read(settingsControllerProvider.notifier);
    await ctrl.setUnit(Unit.lb);
    await ctrl.setRest(90);

    final s = await DriftSettingsRepository(db).get();
    expect(s.unit, Unit.lb);
    expect(s.restTimerSeconds, 90);
  });

  test('theme mode defaults to dark and persists a change', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    final repo = DriftSettingsRepository(db);
    expect((await repo.get()).themeMode, ThemeMode.dark); // brand default

    await container
        .read(settingsControllerProvider.notifier)
        .setThemeMode(ThemeMode.system);
    expect((await repo.get()).themeMode, ThemeMode.system);
  });
}
