import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/date/date_labels.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/history/application/history_view.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/empty_state.dart';

/// History screen: a reverse-chronological list of completed workouts. Tapping
/// a row reveals the exercises done in that session.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.historyTitle)),
      body: AsyncView(
        value: ref.watch(historyViewProvider),
        data: (d) => HistoryView(
          entries: d.entries,
          unit: d.unit,
          loadExercises: (sessionId) =>
              ref.read(sessionExercisesProvider(sessionId).future),
        ),
      ),
    );
  }
}

/// Pure, provider-free rendering of the workout history. The per-session
/// exercise detail is loaded through [loadExercises] on expand.
class HistoryView extends StatelessWidget {
  const HistoryView({
    required this.entries,
    required this.unit,
    required this.loadExercises,
    super.key,
  });

  final List<HistoryEntry> entries;
  final Unit unit;
  final Future<List<SessionExercise>> Function(int sessionId) loadExercises;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return EmptyState(
        AppLocalizations.of(context)!.historyEmptyMessage,
        icon: Icons.history,
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) => _HistoryTile(
        entry: entries[i],
        unit: unit,
        loadExercises: loadExercises,
      ),
    );
  }
}

class _HistoryTile extends StatefulWidget {
  const _HistoryTile({
    required this.entry,
    required this.unit,
    required this.loadExercises,
  });

  final HistoryEntry entry;
  final Unit unit;
  final Future<List<SessionExercise>> Function(int sessionId) loadExercises;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final entry = widget.entry;
    final setsLabel = loc.setsCount(entry.setsLogged);
    final vol = displayWeight(entry.totalVolumeKg, widget.unit);
    final volumeLabel = entry.totalVolumeKg > 0
        ? loc.historyVolume(vol.toStringAsFixed(0), widget.unit.name)
        : null;
    // Sets + volume on one line; the per-exercise top sets show on expand.
    final subtitleParts = <String>[
      setsLabel,
      if (volumeLabel != null) volumeLabel,
    ];

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.check_circle_outline),
          title: Text(entry.dayName),
          subtitle: Text(subtitleParts.join(' · ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDate(loc, entry.date),
                style: theme.textTheme.bodySmall,
              ),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.expand_more),
              ),
            ],
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        if (_expanded)
          FutureBuilder<List<SessionExercise>>(
            future: widget.loadExercises(entry.sessionId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(loc.couldNotLoadExercises),
                );
              }
              final exercises = snapshot.data;
              if (exercises == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                child: Column(
                  children: [
                    for (final e in exercises)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                e.name,
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            Text(
                              e.summary,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}

String _formatDate(AppLocalizations loc, DateTime d) =>
    '${monthShort(loc, d.month)} ${d.day}';
