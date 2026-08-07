import 'package:flutter/material.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// A bottom sheet to edit an exercise's set scheme: sets, reps, and type
/// (Straight / Top-Back-off / Ramp).
Future<void> showSetSchemeEditor(
  BuildContext context, {
  required String name,
  required SetSchemeType initialType,
  required int initialSets,
  required int initialReps,
  required void Function(SetSchemeType type, int sets, int reps) onSave,
}) {
  var type = initialType;
  var sets = initialSets;
  var reps = initialReps;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Scrollable so the Save button is never pushed off a short screen.
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final loc = AppLocalizations.of(context)!;
      return StatefulBuilder(
        builder: (context, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.setSchemeSheetTitle(name),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              _StepperRow(
                label: loc.setsCount(sets),
                onDec: () => setSheet(() => sets = sets <= 1 ? 1 : sets - 1),
                onInc: () => setSheet(() => sets = sets >= 10 ? 10 : sets + 1),
              ),
              _StepperRow(
                label: loc.repsCount(reps),
                onDec: () => setSheet(() => reps = reps <= 1 ? 1 : reps - 1),
                onInc: () => setSheet(() => reps = reps >= 20 ? 20 : reps + 1),
              ),
              const SizedBox(height: 12),
              for (final t in SetSchemeType.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t == type
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: t == type ? theme.colorScheme.primary : null,
                  ),
                  title: Text(t.label(loc)),
                  onTap: () => setSheet(() => type = t),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    onSave(type, sets, reps);
                    Navigator.pop(context);
                  },
                  child: Text(loc.save),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.onDec,
    required this.onInc,
  });

  final String label;
  final VoidCallback onDec;
  final VoidCallback onInc;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: onDec,
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: onInc,
        ),
      ],
    );
  }
}
