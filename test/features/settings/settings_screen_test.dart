import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';
import 'package:openlifts/features/settings/data/settings_repository_impl.dart';
import 'package:openlifts/features/settings/presentation/settings_screen.dart';

import '../../support/test_app.dart';

void main() {
  testWidgets('renders units toggle and deferred backup rows', (tester) async {
    const setting = Setting(
      id: 1,
      unit: Unit.kg,
      barWeightKg: 20,
      restTimerSeconds: 180,
      seedVersion: 0,
      themeMode: ThemeMode.dark,
      languageMode: AppLanguage.system,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => Stream.value(setting)),
        ],
        child: wrapWithLocalizations(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Units'), findsOneWidget);
    expect(find.byType(SegmentedButton<Unit>), findsOneWidget);
    expect(find.text('lb'), findsOneWidget);
    expect(find.text('Back up my data'), findsOneWidget);
  });

  // The controller is obtained with `ref.read(...notifier)` (no listener).
  // If it were auto-disposed it would be torn down before a button's async
  // write completes, its Ref would throw mid-write, and the tap would silently
  // do nothing — the "unresponsive settings buttons" regression. A real
  // in-memory DB (so the write actually lands) plus a static `settingsProvider`
  // stream (so the tree settles rather than animating on a live query) isolates
  // that.
  const kg = Setting(
    id: 1,
    unit: Unit.kg,
    barWeightKg: 20,
    restTimerSeconds: 180,
    seedVersion: 0,
    themeMode: ThemeMode.dark,
    languageMode: AppLanguage.system,
  );

  Future<AppDatabase> pumpSettings(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await DriftSettingsRepository(db).get(); // seed the default row

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          settingsProvider.overrideWith((ref) => Stream.value(kg)),
        ],
        child: wrapWithLocalizations(const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('tapping a unit segment persists the change', (tester) async {
    final db = await pumpSettings(tester);

    await tester.tap(find.text('lb'));
    await tester.pumpAndSettle();

    // Drift serialises on its executor, so this get() runs after the tap's
    // save() — reading the persisted value proves the tap was handled.
    expect((await DriftSettingsRepository(db).get()).unit, Unit.lb);
  });

  testWidgets('tapping a theme segment persists the change', (tester) async {
    final db = await pumpSettings(tester);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    expect(
      (await DriftSettingsRepository(db).get()).themeMode,
      ThemeMode.light,
    );
  });
}
