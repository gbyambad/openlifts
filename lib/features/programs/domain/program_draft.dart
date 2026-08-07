import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/features/programs/domain/program_repository.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// A program being built or edited in the UI, before it is persisted. Pure
/// (no Drift/Riverpod) so the builder logic is unit-testable in isolation.
///
/// It converts to a [NewProgram] via [toSpec] — the same insertion spec the
/// seed uses — so custom programs flow through exactly one write path.
class ProgramDraft {
  const ProgramDraft({
    required this.name,
    required this.weekdays,
    required this.days,
    this.sourceId,
  });

  /// A blank draft: one empty day, trained Mon/Wed/Fri.
  factory ProgramDraft.blank() => const ProgramDraft(
        name: '',
        weekdays: [1, 3, 5],
        days: [DraftDay(name: 'Workout A', exercises: [])],
      );

  final String name;

  /// Training weekdays (1 = Mon … 7 = Sun).
  final List<int> weekdays;
  final List<DraftDay> days;

  /// Set when editing an existing custom program (its id is reused on save).
  final String? sourceId;

  /// Ready to save: a name and at least one day with at least one exercise.
  bool get isSaveable =>
      name.trim().isNotEmpty &&
      days.isNotEmpty &&
      days.any((d) => d.exercises.isNotEmpty);

  ProgramDraft copyWith({
    String? name,
    List<int>? weekdays,
    List<DraftDay>? days,
  }) =>
      ProgramDraft(
        name: name ?? this.name,
        weekdays: weekdays ?? this.weekdays,
        days: days ?? this.days,
        sourceId: sourceId,
      );

  /// The insertion spec for [id]. Empty days are dropped; the schedule is fixed
  /// weekdays when any are chosen, otherwise 3×/week.
  NewProgram toSpec(String id) {
    final kept = days.where((d) => d.exercises.isNotEmpty).toList();
    return NewProgram(
      id: id,
      name: name.trim(),
      progressionStyle: ProgressionStyle.linear,
      scheduleMode: weekdays.isEmpty
          ? ScheduleMode.timesPerWeek
          : ScheduleMode.fixedWeekdays,
      timesPerWeek: weekdays.isEmpty ? 3 : null,
      weekdays: weekdays.isEmpty ? null : (weekdays.toList()..sort()),
      tags: const ['Custom'],
      days: [
        for (var i = 0; i < kept.length; i++)
          NewDay(
            id: '$id-$i',
            name: kept[i].name,
            orderIndex: i,
            prescriptions: [
              for (var j = 0; j < kept[i].exercises.length; j++)
                kept[i].exercises[j].toSpec(j),
            ],
          ),
      ],
    );
  }
}

/// One workout day in a [ProgramDraft].
class DraftDay {
  const DraftDay({required this.name, required this.exercises});

  final String name;
  final List<DraftExercise> exercises;

  DraftDay copyWith({String? name, List<DraftExercise>? exercises}) => DraftDay(
        name: name ?? this.name,
        exercises: exercises ?? this.exercises,
      );
}

/// One exercise slot in a [DraftDay], with its chosen set scheme.
class DraftExercise {
  const DraftExercise({
    required this.exerciseId,
    required this.name,
    required this.type,
    required this.sets,
    required this.reps,
  });

  final String exerciseId;
  final String name;
  final SetSchemeType type;
  final int sets;
  final int reps;

  String summary(AppLocalizations loc) => '$sets×$reps · ${type.label(loc)}';

  DraftExercise copyWith({SetSchemeType? type, int? sets, int? reps}) =>
      DraftExercise(
        exerciseId: exerciseId,
        name: name,
        type: type ?? this.type,
        sets: sets ?? this.sets,
        reps: reps ?? this.reps,
      );

  NewPrescription toSpec(int orderIndex) => NewPrescription(
        exerciseId: exerciseId,
        orderIndex: orderIndex,
        setGroups: buildSetGroups(type, sets, reps),
      );
}
