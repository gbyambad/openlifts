import 'package:flutter/material.dart';
import 'package:openlifts/core/date/date_labels.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// A row of seven Mon–Sun [FilterChip]s for choosing training days. Weekdays
/// are 1 = Mon … 7 = Sun: [isSelected] reports whether one is chosen, and
/// tapping a chip calls [onToggle] with that weekday.
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    required this.isSelected,
    required this.onToggle,
    super.key,
  });

  final bool Function(int day) isSelected;
  final void Function(int day) onToggle;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var day = 1; day <= 7; day++)
          FilterChip(
            label: Text(weekdayShort(loc, day)),
            selected: isSelected(day),
            onSelected: (_) => onToggle(day),
          ),
      ],
    );
  }
}
