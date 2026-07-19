import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/features/programs/application/program_providers.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/programs/domain/program_draft.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'program_builder_controller.g.dart';

/// Drives the program builder: holds an in-progress [ProgramDraft] and persists
/// it through the same `insertProgram` write path the seed uses.
///
/// [editProgramId] is null for a brand-new program; when set, the draft is
/// pre-loaded from that (custom) program's tree and saving overwrites it.
@riverpod
class ProgramBuilderController extends _$ProgramBuilderController {
  @override
  Future<ProgramDraft> build(String? editProgramId) async {
    if (editProgramId == null) return ProgramDraft.blank();

    final tree =
        await ref.read(programRepositoryProvider).loadTree(editProgramId);
    if (tree == null) return ProgramDraft.blank();

    return ProgramDraft(
      name: tree.program.name,
      weekdays: tree.program.weekdays ?? const [1, 3, 5],
      sourceId: editProgramId,
      days: [
        for (final dn in tree.days)
          DraftDay(
            name: dn.day.name,
            exercises: [
              for (final pn in dn.prescriptions)
                () {
                  final s = schemeFromGroups(pn.setGroups);
                  return DraftExercise(
                    exerciseId: pn.exercise.id,
                    name: pn.exercise.name,
                    type: s.type,
                    sets: s.sets,
                    reps: s.reps,
                  );
                }(),
            ],
          ),
      ],
    );
  }

  ProgramDraft? get _draft => state.value;

  void _set(ProgramDraft draft) => state = AsyncData(draft);

  void setName(String name) {
    final d = _draft;
    if (d != null) _set(d.copyWith(name: name));
  }

  void toggleWeekday(int weekday) {
    final d = _draft;
    if (d == null) return;
    final next = [...d.weekdays];
    next.contains(weekday) ? next.remove(weekday) : next.add(weekday);
    _set(d.copyWith(weekdays: next));
  }

  void addDay() {
    final d = _draft;
    if (d == null) return;
    final name = 'Workout ${String.fromCharCode(65 + d.days.length)}'; // A, B…
    _set(
      d.copyWith(days: [...d.days, DraftDay(name: name, exercises: const [])]),
    );
  }

  void removeDay(int dayIndex) {
    final d = _draft;
    if (d == null || d.days.length <= 1) return;
    _set(d.copyWith(days: [...d.days]..removeAt(dayIndex)));
  }

  void renameDay(int dayIndex, String name) =>
      _mutateDay(dayIndex, (day) => day.copyWith(name: name));

  /// Add [exercise] (a catalog row) to [dayIndex] as a straight 5×5 by default.
  void addExercise(int dayIndex, Exercise exercise) => _mutateDay(
        dayIndex,
        (day) => day.copyWith(
          exercises: [
            ...day.exercises,
            DraftExercise(
              exerciseId: exercise.id,
              name: exercise.name,
              type: SetSchemeType.straight,
              sets: 5,
              reps: 5,
            ),
          ],
        ),
      );

  void removeExercise(int dayIndex, int exerciseIndex) => _mutateDay(
        dayIndex,
        (day) => day.copyWith(
          exercises: [...day.exercises]..removeAt(exerciseIndex),
        ),
      );

  void setScheme(
    int dayIndex,
    int exerciseIndex,
    SetSchemeType type,
    int sets,
    int reps,
  ) =>
      _mutateDay(
        dayIndex,
        (day) => day.copyWith(
          exercises: [
            for (var i = 0; i < day.exercises.length; i++)
              if (i == exerciseIndex)
                day.exercises[i].copyWith(type: type, sets: sets, reps: reps)
              else
                day.exercises[i],
          ],
        ),
      );

  void _mutateDay(int dayIndex, DraftDay Function(DraftDay) fn) {
    final d = _draft;
    if (d == null) return;
    _set(
      d.copyWith(
        days: [
          for (var i = 0; i < d.days.length; i++)
            if (i == dayIndex) fn(d.days[i]) else d.days[i],
        ],
      ),
    );
  }

  /// Persist the draft and return the saved program's id, or null if the draft
  /// is not saveable. Reuses the source id when editing so the row is replaced.
  Future<String?> save() async {
    final d = _draft;
    if (d == null || !d.isSaveable) return null;
    final id = d.sourceId ?? 'custom-${DateTime.now().millisecondsSinceEpoch}';
    await ref.read(programRepositoryProvider).insertProgram(d.toSpec(id));
    ref
      ..invalidate(programsViewProvider)
      ..invalidate(todayProvider);
    return id;
  }
}
