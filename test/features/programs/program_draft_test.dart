import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/program_draft.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';

DraftExercise _ex(String id) => DraftExercise(
      exerciseId: id,
      name: id,
      type: SetSchemeType.straight,
      sets: 5,
      reps: 5,
    );

void main() {
  group('isSaveable', () {
    test('a blank draft is not saveable', () {
      expect(ProgramDraft.blank().isSaveable, isFalse);
    });

    test('a named draft with no exercises is not saveable', () {
      final d = ProgramDraft.blank().copyWith(name: 'My Program');
      expect(d.isSaveable, isFalse);
    });

    test('a named draft with at least one exercise is saveable', () {
      final d = ProgramDraft.blank().copyWith(
        name: 'My Program',
        days: [
          DraftDay(name: 'Workout A', exercises: [_ex('squat')]),
        ],
      );
      expect(d.isSaveable, isTrue);
    });
  });

  group('toSpec', () {
    test('trims the name, sorts weekdays, drops empty days, tags Custom', () {
      final draft = ProgramDraft(
        name: '  My Program ',
        weekdays: const [5, 1, 3],
        days: [
          DraftDay(name: 'Day A', exercises: [_ex('squat'), _ex('bench')]),
          const DraftDay(name: 'Empty', exercises: []),
        ],
      );

      final spec = draft.toSpec('custom-1');

      expect(spec.id, 'custom-1');
      expect(spec.name, 'My Program');
      expect(spec.progressionStyle, ProgressionStyle.linear);
      expect(spec.scheduleMode, ScheduleMode.fixedWeekdays);
      expect(spec.weekdays, [1, 3, 5]);
      expect(spec.tags, ['Custom']);

      expect(spec.days.length, 1); // the empty day is dropped
      expect(spec.days.first.id, 'custom-1-0');
      expect(spec.days.first.orderIndex, 0);
      expect(
        spec.days.first.prescriptions.map((p) => p.exerciseId),
        ['squat', 'bench'],
      );
      final groups = spec.days.first.prescriptions.first.setGroups;
      expect(groups.single.sets, 5);
      expect(groups.single.reps, 5);
      expect(groups.single.weightRule, WeightRule.straight);
    });

    test('no chosen weekdays falls back to 3×/week', () {
      final draft = ProgramDraft(
        name: 'Anytime',
        weekdays: const [],
        days: [
          DraftDay(name: 'Full body', exercises: [_ex('squat')]),
        ],
      );

      final spec = draft.toSpec('custom-2');

      expect(spec.scheduleMode, ScheduleMode.timesPerWeek);
      expect(spec.timesPerWeek, 3);
      expect(spec.weekdays, isNull);
    });

    test('a top/back-off scheme expands into two set-groups', () {
      const draft = ProgramDraft(
        name: 'P',
        weekdays: [1],
        days: [
          DraftDay(
            name: 'A',
            exercises: [
              DraftExercise(
                exerciseId: 'squat',
                name: 'Squat',
                type: SetSchemeType.topBackoff,
                sets: 5,
                reps: 5,
              ),
            ],
          ),
        ],
      );

      final groups = draft.toSpec('c').days.first.prescriptions.first.setGroups;
      expect(groups.length, 2);
      expect(groups.first.weightRule, WeightRule.topSet);
      expect(groups.last.weightRule, WeightRule.backoff);
    });
  });
}
