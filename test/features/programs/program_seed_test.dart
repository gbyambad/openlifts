import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/seed/bootstrap.dart';
import 'package:openlifts/features/programs/data/program_repository_impl.dart';

import '../../support/test_database.dart';

Future<String> _asset(String path) => File(path).readAsString();

void main() {
  late AppDatabase db;
  late DriftProgramRepository programs;
  late String exercisesJson;
  late String programsJson;

  setUp(() async {
    db = openTestDb();
    programs = DriftProgramRepository(db);
    exercisesJson = await _asset('assets/seed/exercises.json');
    programsJson = await _asset('assets/seed/programs.json');
  });
  tearDown(() => db.close());

  test('seeds exactly 8 built-in programs, idempotently', () async {
    await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
    expect((await programs.all()).length, 8);

    // Re-running yields the same 8, not 16.
    await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
    expect((await programs.all()).length, 8);
  });

  test("re-seeding does not duplicate a program's prescriptions", () async {
    await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
    final firstDay = (await programs.loadTree('stronglifts-5x5'))!.days.first;
    final before = firstDay.prescriptions.length;
    expect(before, greaterThan(0));

    // A second seed pass must replace, not append.
    await runSeed(db, exercisesJson: exercisesJson, programsJson: programsJson);
    final after =
        (await programs.loadTree('stronglifts-5x5'))!.days.first.prescriptions;
    expect(after.length, before);
  });

  test('ensureSeeded gates on seedVersion and preserves custom programs',
      () async {
    await ensureSeeded(
      db,
      exercisesJson: exercisesJson,
      programsJson: programsJson,
    );
    await programs.copyAsCustom(
      'stronglifts-5x5',
      newId: 'mine',
      newName: 'Mine',
    );

    // Second call: seedVersion already current -> no re-seed; custom survives.
    await ensureSeeded(
      db,
      exercisesJson: exercisesJson,
      programsJson: programsJson,
    );
    final all = await programs.all();
    expect(all.length, 9); // 8 built-in + 1 custom
    expect(all.any((p) => p.id == 'mine'), isTrue);
  });
}
