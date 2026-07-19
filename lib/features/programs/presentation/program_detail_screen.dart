import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/features/programs/application/program_detail.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/weekday_picker.dart';

/// Program detail: its workout structure plus a training-day picker. Choosing
/// days and tapping "Use this program" makes it the active program.
class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({required this.programId, super.key});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(programDetailProvider(programId)),
      data: (detail) => detail == null
          ? const Scaffold(body: Center(child: Text('Program not found.')))
          : _Detail(detail: detail),
    );
  }
}

class _Detail extends ConsumerStatefulWidget {
  const _Detail({required this.detail});

  final ProgramDetail detail;

  @override
  ConsumerState<_Detail> createState() => _DetailState();
}

class _DetailState extends ConsumerState<_Detail> {
  late final Set<int> _days = widget.detail.weekdays.toSet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = widget.detail;

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Training days', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Pick the days you train. Workouts rotate across them.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                WeekdayPicker(
                  isSelected: _days.contains,
                  onToggle: (day) => setState(
                    () => _days.contains(day)
                        ? _days.remove(day)
                        : _days.add(day),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Workouts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final w in d.workouts) _WorkoutOutlineCard(workout: w),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _days.isEmpty
                    ? null
                    : () async {
                        final router = GoRouter.of(context);
                        await ref
                            .read(programsControllerProvider.notifier)
                            .useProgram(d.id, _days.toList()..sort());
                        router.go('/today');
                      },
                child:
                    Text(d.isActive ? 'Update schedule' : 'Use this program'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutOutlineCard extends StatelessWidget {
  const _WorkoutOutlineCard({required this.workout});

  final WorkoutOutline workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workout.name, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final e in workout.exercises)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(e, style: theme.textTheme.bodyLarge),
              ),
          ],
        ),
      ),
    );
  }
}
