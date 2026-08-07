import 'package:flutter/material.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/weekday_picker.dart';

/// A lightweight day-picker sheet used both to activate a program (first-time
/// "pick your days") and to change an active program's schedule later — the
/// schedule is edited on its own, without touching the workout structure.
///
/// [onConfirm] receives the chosen weekdays (1 = Mon … 7 = Sun, sorted). The
/// confirm button is disabled until at least one day is chosen.
Future<void> showScheduleSheet(
  BuildContext context, {
  required String title,
  required String ctaLabel,
  required List<int> initialWeekdays,
  required void Function(List<int> weekdays) onConfirm,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Scrollable so the picker never overflows on short screens.
    isScrollControlled: true,
    builder: (context) => _ScheduleSheet(
      title: title,
      ctaLabel: ctaLabel,
      initialWeekdays: initialWeekdays,
      onConfirm: onConfirm,
    ),
  );
}

class _ScheduleSheet extends StatefulWidget {
  const _ScheduleSheet({
    required this.title,
    required this.ctaLabel,
    required this.initialWeekdays,
    required this.onConfirm,
  });

  final String title;
  final String ctaLabel;
  final List<int> initialWeekdays;
  final void Function(List<int> weekdays) onConfirm;

  @override
  State<_ScheduleSheet> createState() => _ScheduleSheetState();
}

class _ScheduleSheetState extends State<_ScheduleSheet> {
  late final Set<int> _days = widget.initialWeekdays.toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.pickTrainingDaysHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          WeekdayPicker(
            isSelected: _days.contains,
            onToggle: (day) => setState(
              () => _days.contains(day) ? _days.remove(day) : _days.add(day),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _days.isEmpty
                  ? null
                  : () {
                      widget.onConfirm(_days.toList()..sort());
                      Navigator.pop(context);
                    },
              child: Text(widget.ctaLabel),
            ),
          ),
        ],
      ),
    );
  }
}
