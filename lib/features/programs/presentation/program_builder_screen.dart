import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/features/programs/application/program_builder_controller.dart';
import 'package:openlifts/features/programs/domain/program_draft.dart';
import 'package:openlifts/features/programs/presentation/exercise_picker_sheet.dart';
import 'package:openlifts/features/programs/presentation/set_scheme_sheet.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/weekday_picker.dart';

/// Build a custom program from scratch, or edit an existing custom one when
/// [editProgramId] is set. Name it, pick training days, add workout days, and
/// fill each with exercises and their set schemes.
class ProgramBuilderScreen extends ConsumerWidget {
  const ProgramBuilderScreen({this.editProgramId, super.key});

  final String? editProgramId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(programBuilderControllerProvider(editProgramId)),
      data: (draft) => _Builder(editProgramId: editProgramId, initial: draft),
    );
  }
}

class _Builder extends ConsumerStatefulWidget {
  const _Builder({required this.editProgramId, required this.initial});

  final String? editProgramId;
  final ProgramDraft initial;

  @override
  ConsumerState<_Builder> createState() => _BuilderState();
}

class _BuilderState extends ConsumerState<_Builder> {
  late final TextEditingController _name =
      TextEditingController(text: widget.initial.name);

  ProgramBuilderController get _ctrl =>
      ref.read(programBuilderControllerProvider(widget.editProgramId).notifier);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    // The name lives in the local controller; everything else reflects state.
    final draft = ref
            .watch(programBuilderControllerProvider(widget.editProgramId))
            .value ??
        widget.initial;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editProgramId == null
              ? loc.newProgramTitle
              : loc.editProgramTitle,
        ),
        actions: [
          TextButton(
            onPressed: draft.isSaveable ? _save : null,
            child: Text(loc.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: loc.programNameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: _ctrl.setName,
          ),
          const SizedBox(height: 20),
          Text(loc.trainingDays, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          WeekdayPicker(
            isSelected: draft.weekdays.contains,
            onToggle: _ctrl.toggleWeekday,
          ),
          const SizedBox(height: 24),
          Text(loc.workoutsLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (var di = 0; di < draft.days.length; di++)
            _DayCard(
              day: draft.days[di],
              canRemove: draft.days.length > 1,
              onRename: (name) => _ctrl.renameDay(di, name),
              onRemoveDay: () => _ctrl.removeDay(di),
              onAddExercise: () => _addExercise(di),
              onRemoveExercise: (ei) => _ctrl.removeExercise(di, ei),
              onEditScheme: (ei) => _editScheme(di, ei, draft),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ctrl.addDay,
            icon: const Icon(Icons.add),
            label: Text(loc.addWorkoutDay),
          ),
        ],
      ),
    );
  }

  Future<void> _addExercise(int dayIndex) async {
    final exercise = await showExercisePicker(context);
    if (exercise != null) _ctrl.addExercise(dayIndex, exercise);
  }

  Future<void> _editScheme(int dayIndex, int exIndex, ProgramDraft draft) {
    final ex = draft.days[dayIndex].exercises[exIndex];
    return showSetSchemeEditor(
      context,
      name: ex.name,
      initialType: ex.type,
      initialSets: ex.sets,
      initialReps: ex.reps,
      onSave: (type, sets, reps) =>
          _ctrl.setScheme(dayIndex, exIndex, type, sets, reps),
    );
  }

  Future<void> _save() async {
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context)!;
    final id = await _ctrl.save();
    if (id == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(loc.programSavedMessage)),
    );
    router.go('/programs');
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.canRemove,
    required this.onRename,
    required this.onRemoveDay,
    required this.onAddExercise,
    required this.onRemoveExercise,
    required this.onEditScheme,
  });

  final DraftDay day;
  final bool canRemove;
  final void Function(String name) onRename;
  final VoidCallback onRemoveDay;
  final VoidCallback onAddExercise;
  final void Function(int exerciseIndex) onRemoveExercise;
  final void Function(int exerciseIndex) onEditScheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(day.name, style: theme.textTheme.titleSmall),
                ),
                IconButton(
                  tooltip: loc.renameDayTooltip,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _rename(context),
                ),
                IconButton(
                  tooltip: loc.removeDayTooltip,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: canRemove ? onRemoveDay : null,
                ),
              ],
            ),
            if (day.exercises.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  loc.noExercisesYet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (var ei = 0; ei < day.exercises.length; ei++)
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 4),
                  title: Text(day.exercises[ei].name),
                  subtitle: Text(day.exercises[ei].summary(loc)),
                  onTap: () => onEditScheme(ei),
                  trailing: IconButton(
                    tooltip: loc.removeExerciseTooltip,
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => onRemoveExercise(ei),
                  ),
                ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAddExercise,
              icon: const Icon(Icons.add),
              label: Text(loc.addExercise),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: day.name);
    String? name;
    try {
      name = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(loc.renameDayTooltip),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(loc.save),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
    if (name != null && name.isNotEmpty) onRename(name);
  }
}
