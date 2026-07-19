import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/sessions/data/session_repository_impl.dart';

void main() {
  late AppDatabase db;
  late DriftSessionRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftSessionRepository(db);
  });
  tearDown(() => db.close());

  Future<void> insertDay(String id, String name) =>
      db.into(db.programDays).insert(
            ProgramDaysCompanion.insert(
              id: id,
              programId: 'prog',
              name: name,
              orderIndex: 0,
            ),
          );

  test('summarises completed workouts newest-first with day name and top set',
      () async {
    await insertDay('dayA', 'Workout A');

    final s1 = await repo.startSession('dayA', DateTime(2026, 3, 2));
    await repo.logSet(
      sessionId: s1,
      exerciseId: 'squat',
      setIndex: 0,
      weightKg: 60,
      targetReps: 5,
      actualReps: 5,
    );
    await repo.logSet(
      sessionId: s1,
      exerciseId: 'squat',
      setIndex: 1,
      weightKg: 62.5,
      targetReps: 5,
      actualReps: 5,
    );
    await repo.completeSession(s1, DateTime(2026, 3, 2, 10));

    final s2 = await repo.startSession('dayA', DateTime(2026, 3, 5));
    await repo.completeSession(s2, DateTime(2026, 3, 5, 10));

    // An in-progress session must not appear.
    await repo.startSession('dayA', DateTime(2026, 3, 6));

    final history = await repo.watchHistory().first;
    expect(history.map((e) => e.sessionId), [s2, s1]); // newest first
    final first = history.firstWhere((e) => e.sessionId == s1);
    expect(first.dayName, 'Workout A');
    expect(first.setsLogged, 2);
    expect(first.topSetKg, 62.5);
    // Volume = 60×5 + 62.5×5 = 612.5.
    expect(first.totalVolumeKg, 612.5);
  });

  test('unknown program day falls back to a generic name', () async {
    final s = await repo.startSession('ghost', DateTime(2026, 3, 2));
    await repo.completeSession(s, DateTime(2026, 3, 2, 10));

    final history = await repo.watchHistory().first;
    expect(history.single.dayName, 'Workout');
    expect(history.single.setsLogged, 0);
    expect(history.single.topSetKg, isNull);
  });
}
