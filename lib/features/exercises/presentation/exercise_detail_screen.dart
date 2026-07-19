import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/app_database.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/exercises/application/exercise_detail.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/shared/widgets/async_view.dart';

/// Exercise detail: how-to instructions plus this lift's recent history.
class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({required this.exerciseId, super.key});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(exerciseDetailProvider(exerciseId)),
      data: (d) => d == null
          ? const Scaffold(body: Center(child: Text('Exercise not found.')))
          : ExerciseDetailView(
              exercise: d.exercise,
              history: d.history,
              unit: d.unit,
            ),
    );
  }
}

/// Pure, provider-free rendering of an exercise's detail.
class ExerciseDetailView extends StatelessWidget {
  const ExerciseDetailView({
    required this.exercise,
    required this.history,
    required this.unit,
    super.key,
  });

  final Exercise exercise;
  final List<WeightPoint> history;
  final Unit unit;

  String _weight(double kg) =>
      '${displayWeight(kg, unit).toStringAsFixed(0)} ${unit.name}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <String>[
      exercise.equipment.name,
      if (exercise.mechanic != null) exercise.mechanic!.name,
      if (exercise.movementPattern != null) exercise.movementPattern!.name,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in chips) Chip(label: Text(c))],
          ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Current', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              _weight(history.last.weightKg),
              style: theme.textTheme.headlineSmall
                  ?.copyWith(color: theme.colorScheme.primary),
            ),
          ],
          const SizedBox(height: 16),
          Text('How to perform', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (exercise.instructions.isEmpty)
            Text('No instructions yet.', style: theme.textTheme.bodyMedium)
          else
            for (var i = 0; i < exercise.instructions.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.  ',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary),
                    ),
                    Expanded(
                      child: Text(
                        exercise.instructions[i],
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
          if (history.length > 1) ...[
            const SizedBox(height: 16),
            Text('Recent top sets', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final p in history.reversed.take(8))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_ymd(p.date), style: theme.textTheme.bodyMedium),
                    Text(
                      _weight(p.weightKg),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

String _ymd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
