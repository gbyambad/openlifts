import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/core/theme/app_text_styles.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/programs/application/program_weights.dart';
import 'package:openlifts/features/programs/application/programs_view.dart';
import 'package:openlifts/features/programs/domain/set_scheme.dart';
import 'package:openlifts/features/programs/presentation/program_schedule_sheet.dart';
import 'package:openlifts/features/programs/presentation/set_scheme_sheet.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/confirm_dialog.dart';
import 'package:openlifts/shared/widgets/empty_state.dart';
import 'package:openlifts/shared/widgets/plate_bar.dart';

/// Programs: pick the active program (Programs tab) or edit its working weights
/// (Weights tab).
class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Programs'),
          actions: [
            TextButton(
              onPressed: () => context.push('/programs/new'),
              child: const Text('Create'),
            ),
          ],
          bottom: TabBar(
            labelStyle: AppTextStyles.of(context).tabLabel,
            unselectedLabelStyle: AppTextStyles.of(context).tabLabelMuted,
            tabs: const [Tab(text: 'Programs'), Tab(text: 'Weights')],
          ),
        ),
        body: const TabBarView(
          children: [_ProgramsList(), _WeightsTab()],
        ),
      ),
    );
  }
}

class _ProgramsList extends ConsumerWidget {
  const _ProgramsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(programsViewProvider),
      data: (view) {
        if (view.isEmpty) {
          return const EmptyState(
            'No programs yet.\nTap Create to build one.',
            icon: Icons.list_alt_outlined,
          );
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (view.active != null)
              _CurrentProgramCard(card: view.active!)
            else
              const _NoActiveBanner(),
            if (view.custom.isNotEmpty) ...[
              const _SectionHeader('My programs'),
              for (final c in view.custom) _ProgramRow(card: c),
            ],
            if (view.templates.isNotEmpty) ...[
              const _SectionHeader('Templates'),
              for (final c in view.templates) _ProgramRow(card: c),
            ],
          ],
        );
      },
    );
  }
}

/// Opens the day-picker to activate [card] (or, for the active program, to
/// change its schedule) and shows a confirmation.
Future<void> _activate(BuildContext context, WidgetRef ref, ProgramCard card) {
  final messenger = ScaffoldMessenger.of(context);
  return showScheduleSheet(
    context,
    title: card.name,
    ctaLabel: card.isActive ? 'Update schedule' : 'Use this program',
    initialWeekdays: card.weekdays,
    onConfirm: (weekdays) async {
      await ref
          .read(programsControllerProvider.notifier)
          .useProgram(card.id, weekdays);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            card.isActive ? 'Schedule updated' : '${card.name} is now active',
          ),
        ),
      );
    },
  );
}

/// The active program, pinned on top: name, schedule, next session, and the
/// two things you actually do — start today's workout, or change the days.
class _CurrentProgramCard extends ConsumerWidget {
  const _CurrentProgramCard({required this.card});

  final ProgramCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Light: a clean near-white surface (the tinted fill read as muddy on the
    // warm paper ground). Dark: keep the subtle primary tint, which reads well.
    final fill = theme.brightness == Brightness.light
        ? scheme.surface
        : scheme.primaryContainer.withValues(alpha: 0.4);
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CURRENT PROGRAM',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                // Menu here keeps the action row below full-width.
                _ProgramMenu(card: card),
              ],
            ),
            const SizedBox(height: 2),
            Text(card.name, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(card.scheduleSummary, style: theme.textTheme.bodyMedium),
              ],
            ),
            if (card.nextWorkout != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.play_arrow, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Next: ${card.nextWorkout}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/today'),
                    icon: const Icon(Icons.fitness_center, size: 18),
                    label: const Text('Start', maxLines: 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _activate(context, ref, card),
                    icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                    label: const Text('Schedule', maxLines: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveBanner extends StatelessWidget {
  const _NoActiveBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No active program. Pick one below to start training.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        label,
        style: AppTextStyles.of(context).sectionHeader?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

/// A selectable program row. Tapping it opens the day-picker to activate it;
/// the chevron opens the full detail, and the overflow menu duplicates/edits.
class _ProgramRow extends ConsumerWidget {
  const _ProgramRow({required this.card});

  final ProgramCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(
        card.name,
        style: AppTextStyles.of(context).cardTitle,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.scheduleSummary),
          if (card.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [for (final tag in card.tags) _Tag(label: tag)],
              ),
            ),
        ],
      ),
      isThreeLine: card.tags.isNotEmpty,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ProgramMenu(card: card),
          IconButton(
            tooltip: 'Details',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => context.push('/programs/${card.id}'),
          ),
        ],
      ),
      onTap: () => _activate(context, ref, card),
    );
  }
}

/// The overflow menu on a program card: duplicate any program into an editable
/// custom copy; edit or delete custom programs.
class _ProgramMenu extends ConsumerWidget {
  const _ProgramMenu({required this.card});

  final ProgramCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'duplicate',
          child: Text('Duplicate & customize'),
        ),
        if (!card.isBuiltIn) ...[
          const PopupMenuItem(value: 'edit', child: Text('Edit')),
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
      ],
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, String action) async {
    final controller = ref.read(programsControllerProvider.notifier);
    final router = GoRouter.of(context);
    switch (action) {
      case 'duplicate':
        final newId = await controller.duplicate(card.id);
        unawaited(router.push('/programs/$newId/edit'));
      case 'edit':
        unawaited(router.push('/programs/${card.id}/edit'));
      case 'delete':
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete "${card.name}"?',
          message: 'This removes the program. It cannot be undone.',
          confirmLabel: 'Delete',
        );
        if (confirmed ?? false) await controller.deleteProgram(card.id);
    }
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}

class _WeightsTab extends ConsumerWidget {
  const _WeightsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(programWeightsProvider),
      data: (weights) => weights == null
          ? const EmptyState(
              'No active program yet.\nPick one in the Programs tab.',
              icon: Icons.fitness_center,
            )
          : ListView(
              children: [
                for (final workout in weights.workouts) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Text(
                      workout.dayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  const Divider(height: 1),
                  for (final e in workout.entries)
                    ListTile(
                      title: Text(
                        e.name,
                        style: AppTextStyles.of(context).cardTitle,
                      ),
                      subtitle: Text('${e.sets}×${e.reps} · ${e.type.label}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            weightLabel(e.workingKg, weights.unit),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            tooltip: 'Sets & reps',
                            icon: const Icon(Icons.tune),
                            onPressed: () => showSetSchemeEditor(
                              context,
                              name: e.name,
                              initialType: e.type,
                              initialSets: e.sets,
                              initialReps: e.reps,
                              onSave: (type, sets, reps) => ref
                                  .read(
                                    programWeightsControllerProvider.notifier,
                                  )
                                  .setScheme(e.exerciseId, type, sets, reps),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => showWeightEditor(
                        context,
                        title: e.name,
                        initialKg: e.workingKg,
                        unit: weights.unit,
                        barKg: weights.barWeightKg,
                        onChanged: (kg) => ref
                            .read(programWeightsControllerProvider.notifier)
                            .setWeight(e.exerciseId, kg),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
