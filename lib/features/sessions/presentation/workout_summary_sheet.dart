import 'package:flutter/material.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/l10n/app_localizations.dart';

/// A celebratory end-of-workout summary: sets logged and total volume, shown
/// after a session is saved.
Future<void> showWorkoutSummary(
  BuildContext context, {
  required String dayName,
  required int setsDone,
  required double volumeKg,
  required Unit unit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final loc = AppLocalizations.of(context)!;
      final volume = formatWeight(displayWeight(volumeKg, unit));
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.15),
              ),
              child: Icon(Icons.check_rounded, size: 44, color: scheme.primary),
            ),
            const SizedBox(height: 16),
            Text(loc.niceWork, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              loc.dayCompleteLabel(dayName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _Stat(label: loc.setsLoggedLabel, value: '$setsDone'),
                ),
                Expanded(
                  child: _Stat(
                    label: loc.totalVolumeLabel,
                    value: '$volume ${unit.name}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(loc.done),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
