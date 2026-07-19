import 'package:flutter/material.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/workout/domain/plate_math.dart';

/// Shows the per-side load and a barbell plate diagram for a weight (in kg,
/// displayed in [unit]). Used wherever a working weight is edited.
class PlateHint extends StatelessWidget {
  const PlateHint({
    required this.weightKg,
    required this.unit,
    required this.barKg,
    super.key,
  });

  final double weightKg;
  final Unit unit;
  final double barKg;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = displayWeight(weightKg, unit);
    final bar = displayWeight(barKg, unit);
    final load = platesPerSide(total, bar, platesFor(unit));

    final label = load.perSide.isEmpty && load.leftover == 0
        ? 'Empty bar'
        : '${load.leftover > 0 ? '≈ ' : ''}'
            '${formatWeight(load.perSideTotal)} ${unit.name} / side';

    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        PlateBar(perSide: load.perSide),
      ],
    );
  }
}

/// A simple barbell diagram: a sleeve stub plus one plate per entry, sized by
/// weight and labelled.
class PlateBar extends StatelessWidget {
  const PlateBar({required this.perSide, super.key});

  final List<double> perSide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (perSide.isEmpty) return const SizedBox(height: 76);
    final heaviest = perSide.first;

    return SizedBox(
      height: 76,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 24, height: 8, color: scheme.outline),
          for (final p in perSide)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Container(
                width: 22,
                height: 34 + 42 * (p / heaviest),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Text(
                      formatWeight(p),
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Container(width: 14, height: 8, color: scheme.outline),
        ],
      ),
    );
  }
}

/// A reusable weight stepper + plate hint in a modal bottom sheet. Returns when
/// the sheet is dismissed; [onChanged] fires live on each ±2.5 kg step.
Future<void> showWeightEditor(
  BuildContext context, {
  required String title,
  required double initialKg,
  required Unit unit,
  required double barKg,
  required void Function(double kg) onChanged,
}) {
  var kg = initialKg;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    // Scrollable so the Done button / plate diagram never overflow a short
    // screen (they used to clip below the fold).
    isScrollControlled: true,
    builder: (context) {
      final theme = Theme.of(context);
      return StatefulBuilder(
        builder: (context, setSheet) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    iconSize: 32,
                    icon: const Icon(Icons.remove),
                    onPressed: () {
                      setSheet(() => kg = kg <= 2.5 ? 0 : kg - 2.5);
                      onChanged(kg);
                    },
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      weightLabel(kg, unit),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  IconButton.filledTonal(
                    iconSize: 32,
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      setSheet(() => kg += 2.5);
                      onChanged(kg);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlateHint(weightKg: kg, unit: unit, barKg: barKg),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
