import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/settings/application/settings_providers.dart';

Future<(AppDatabase, ProviderContainer)> _seeded() async {
  final db = AppDatabase(NativeDatabase.memory());
  await runSeed(
    db,
    exercisesJson: await File('assets/seed/exercises.json').readAsString(),
    programsJson: await File('assets/seed/programs.json').readAsString(),
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  return (db, container);
}

void main() {
  test('selecting a program sets it active', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await container
        .read(programsControllerProvider.notifier)
        .selectActive('madcow-5x5');

    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.activeProgramId, 'madcow-5x5');
  });

  test('changing a schedule edits the program in place, without forking',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final before =
        (await container.read(programRepositoryProvider).all()).length;
    await container
        .read(programsControllerProvider.notifier)
        .setTimesPerWeek('stronglifts-5x5', 4);

    final all = await container.read(programRepositoryProvider).all();
    expect(all.length, before); // no "(Custom)" clone created

    final builtin = all.firstWhere((p) => p.id == 'stronglifts-5x5');
    expect(builtin.timesPerWeek, 4); // edited in place

    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.activeProgramId, 'stronglifts-5x5'); // the built-in itself
  });

  test('programsView pins the active program and groups the templates',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await container
        .read(programsControllerProvider.notifier)
        .useProgram('stronglifts-5x5', [1, 3, 5]); // activates in place

    final view = await container.read(programsViewProvider.future);
    expect(view.active, isNotNull);
    expect(view.active!.id, 'stronglifts-5x5'); // no fork
    expect(view.active!.isActive, isTrue);
    // The active program is pulled out of the template list, not duplicated.
    expect(view.templates.any((c) => c.id == view.active!.id), isFalse);
    expect(view.templates, isNotEmpty);
    expect(view.templates.every((c) => c.isBuiltIn), isTrue);
  });

  test('duplicate creates an editable custom copy, leaving the original',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final ctrl = container.read(programsControllerProvider.notifier);
    final newId = await ctrl.duplicate('stronglifts-5x5');

    final repo = container.read(programRepositoryProvider);
    final all = await repo.all();
    final copy = all.firstWhere((p) => p.id == newId);
    expect(copy.isBuiltIn, isFalse);
    expect(copy.name, endsWith('(Copy)'));

    // The original is untouched and the copy mirrors its day structure.
    final original = all.firstWhere((p) => p.id == 'stronglifts-5x5');
    expect(original.isBuiltIn, isTrue);
    final originalTree = await repo.loadTree('stronglifts-5x5');
    final copyTree = await repo.loadTree(newId);
    expect(copyTree!.days.length, originalTree!.days.length);
  });

  test('deleting the active custom program removes it and clears active',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final ctrl = container.read(programsControllerProvider.notifier);
    final newId = await ctrl.duplicate('stronglifts-5x5');
    await ctrl.selectActive(newId);

    await ctrl.deleteProgram(newId);

    final repo = container.read(programRepositoryProvider);
    expect((await repo.all()).any((p) => p.id == newId), isFalse);
    expect(await repo.loadTree(newId), isNull);

    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.activeProgramId, isNull);
  });

  test('useProgram sets the chosen weekdays and activates the program in place',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    await container
        .read(programsControllerProvider.notifier)
        .useProgram('stronglifts-5x5', [2, 5]); // Tue, Fri

    final program = (await container.read(programRepositoryProvider).all())
        .firstWhere((p) => p.id == 'stronglifts-5x5');
    expect(program.scheduleMode, ScheduleMode.fixedWeekdays);
    expect(program.weekdays, [2, 5]);

    final settings = await container.read(settingsRepositoryProvider).get();
    expect(settings.activeProgramId, 'stronglifts-5x5');
  });
}
