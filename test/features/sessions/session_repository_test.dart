import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/sessions/data/session_repository_impl.dart';

import '../../support/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftSessionRepository repo;

  setUp(() async {
    db = openTestDb();
    repo = DriftSessionRepository(db);
    await db.into(db.programs).insert(
          ProgramsCompanion.insert(
            id: 'p',
            name: 'P',
            progressionStyle: ProgressionStyle.linear,
            scheduleMode: ScheduleMode.timesPerWeek,
          ),
        );
    await db.into(db.programDays).insert(
          ProgramDaysCompanion.insert(
            id: 'a',
            programId: 'p',
            name: 'A',
            orderIndex: 0,
          ),
        );
    await db.into(db.exercises).insert(
          ExercisesCompanion.insert(
            id: 'squat',
            name: 'Squat',
            equipment: Equipment.barbell,
            incrementKg: 2.5,
          ),
        );
  });
  tearDown(() => db.close());

  test('logs a session with per-set weights and completes it', () async {
    final sessionId = await repo.startSession('a', DateTime(2026, 7, 18));
    await repo.logSet(
      sessionId: sessionId,
      exerciseId: 'squat',
      setIndex: 1,
      weightKg: 60,
      targetReps: 5,
      actualReps: 5,
    );
    await repo.logSet(
      sessionId: sessionId,
      exerciseId: 'squat',
      setIndex: 2,
      weightKg: 62.5,
      targetReps: 5,
      actualReps: 5,
    );

    final sets = await repo.setsFor(sessionId);
    expect(sets.map((s) => s.weightKg).toList(), [60, 62.5]);

    await repo.completeSession(sessionId, DateTime(2026, 7, 18, 1));
    final recent = await repo.watchRecent().first;
    expect(recent.single.completedAt, isNotNull);
  });
}
