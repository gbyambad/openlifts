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

  test('watchLiftSeries returns only logged sets from completed sessions',
      () async {
    final done = await repo.startSession('dayA', DateTime(2026, 3));
    await repo.logSet(
      sessionId: done,
      exerciseId: 'squat',
      setIndex: 0,
      weightKg: 60,
      targetReps: 5,
      actualReps: 5,
    );
    // Unlogged set (actualReps null) in the same session — excluded.
    await repo.logSet(
      sessionId: done,
      exerciseId: 'squat',
      setIndex: 1,
      weightKg: 60,
      targetReps: 5,
    );
    await repo.completeSession(done, DateTime(2026, 3, 1, 1));

    // In-progress session (no completedAt) — excluded entirely.
    final open = await repo.startSession('dayA', DateTime(2026, 3, 3));
    await repo.logSet(
      sessionId: open,
      exerciseId: 'squat',
      setIndex: 0,
      weightKg: 65,
      targetReps: 5,
      actualReps: 5,
    );

    final series = await repo.watchLiftSeries().first;
    expect(series, hasLength(1));
    expect(series.single.exerciseId, 'squat');
    expect(series.single.weightKg, 60);
    expect(series.single.date, DateTime(2026, 3));
  });
}
