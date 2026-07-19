import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/features/home/application/today_providers.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/empty_state.dart';

/// Home / today screen: the active program's next scheduled workouts, each with
/// its exercises and the loads to hit; the nearest one starts a session.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SvgPicture.asset('assets/brand/openlifts-logo.svg', width: 26),
            const SizedBox(width: 8),
            const Text('OpenLifts'),
          ],
        ),
      ),
      body: AsyncView(
        value: ref.watch(todayProvider),
        data: (view) => view == null || view.workouts.isEmpty
            ? const EmptyState(
                'No active program yet.\nPick one in the Programs tab.',
                icon: Icons.fitness_center,
              )
            : _Home(view: view),
      ),
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.view});

  final TodayView view;

  @override
  Widget build(BuildContext context) {
    final next = view.workouts.first;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(
                  view.programName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              for (final w in view.workouts) _WorkoutCard(workout: w),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => context.go('/today/workout/${next.dayId}'),
              child: const Text('Start workout'),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.workout});

  final PlannedWorkout workout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: workout.isNext
          ? scheme.primary.withValues(alpha: 0.08)
          : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: workout.isNext
            ? BorderSide(color: scheme.primary.withValues(alpha: 0.5))
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tapping the card opens the workout detail — same as Start.
        onTap: () => context.go('/today/workout/${workout.dayId}'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (workout.isNext) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'NEXT',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      workout.dayName,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    workout.dateLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: workout.isNext
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: workout.isNext ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final e in workout.exercises)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(e.name, style: theme.textTheme.bodyLarge),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        e.scheme,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
