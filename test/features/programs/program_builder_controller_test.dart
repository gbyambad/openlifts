import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/providers/database_provider.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/exercises/application/exercises_providers.dart';
import 'package:openlifts/features/programs/application/program_builder_controller.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';

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

Future<Exercise> _anExercise(ProviderContainer c) async {
  final all = await c.read(exerciseRepositoryProvider).watchAll().first;
  return all.firstWhere((e) => e.id == 'squat');
}

void main() {
  test('save persists a new custom program that loads back as a tree',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = programBuilderControllerProvider(null);
    await container.read(provider.future);
    final ctrl = container.read(provider.notifier);
    final squat = await _anExercise(container);

    ctrl
      ..setName('My Program')
      ..addExercise(0, squat);
    final id = await ctrl.save();
    expect(id, isNotNull);

    final repo = container.read(programRepositoryProvider);
    final tree = await repo.loadTree(id!);
    expect(tree, isNotNull);
    expect(tree!.program.name, 'My Program');
    expect(tree.program.isBuiltIn, isFalse);
    expect(tree.days.single.prescriptions.single.exercise.id, 'squat');
  });

  test('an unsaveable draft (no exercises) does not persist', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = programBuilderControllerProvider(null);
    await container.read(provider.future);
    final ctrl = container.read(provider.notifier)..setName('Empty');

    final before =
        (await container.read(programRepositoryProvider).all()).length;
    final id = await ctrl.save();
    final after =
        (await container.read(programRepositoryProvider).all()).length;

    expect(id, isNull);
    expect(after, before);
  });

  test('editing an existing custom program loads it and overwrites on save',
      () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    // First create one.
    final create = programBuilderControllerProvider(null);
    await container.read(create.future);
    final squat = await _anExercise(container);
    final createCtrl = container.read(create.notifier)
      ..setName('First name')
      ..addExercise(0, squat);
    final id = (await createCtrl.save())!;

    // Now edit it.
    final editProvider = programBuilderControllerProvider(id);
    final draft = await container.read(editProvider.future);
    expect(draft.name, 'First name');
    expect(draft.sourceId, id);
    expect(draft.days.single.exercises.single.exerciseId, 'squat');

    final editCtrl = container.read(editProvider.notifier)..setName('Renamed');
    final savedId = await editCtrl.save();
    expect(savedId, id); // same id reused

    final tree = await container.read(programRepositoryProvider).loadTree(id);
    expect(tree!.program.name, 'Renamed');
  });

  test('setScheme changes an exercise scheme in the draft', () async {
    final (db, container) = await _seeded();
    addTearDown(db.close);
    addTearDown(container.dispose);

    final provider = programBuilderControllerProvider(null);
    await container.read(provider.future);
    final squat = await _anExercise(container);
    container.read(provider.notifier)
      ..addExercise(0, squat)
      ..setScheme(0, 0, SetSchemeType.topBackoff, 5, 3);

    final ex = container.read(provider).value!.days[0].exercises[0];
    expect(ex.type, SetSchemeType.topBackoff);
    expect(ex.reps, 3);
  });
}
