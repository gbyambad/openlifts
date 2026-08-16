import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/progress/application/progress_view.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/features/progress/domain/progress_summary.dart';
import 'package:openlifts/features/sessions/domain/session_repository.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/empty_state.dart';

/// Progress screen: a range-filtered summary of training — top-line stats, a
/// weight-over-time chart per trained lift (plus bodyweight and volume), and
/// each lift's personal record.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.progressTitle)),
      body: AsyncView(
        value: ref.watch(progressViewProvider),
        data: (d) => ProgressView(
          charts: d.charts,
          bodyweight: d.bodyweight,
          history: d.history,
          unit: d.unit,
          onOpenLift: (id) => context.push('/progress/exercises/$id'),
        ),
      ),
    );
  }
}

/// Which chart is shown in the "Charts" section.
enum _ChartTab { weight, strength, volume }

/// Pure, provider-free rendering of the progress screen.
class ProgressView extends StatefulWidget {
  const ProgressView({
    required this.charts,
    required this.bodyweight,
    required this.unit,
    this.history = const [],
    this.onOpenLift,
    super.key,
  });

  final List<LiftChart> charts;
  final List<WeightPoint> bodyweight;
  final List<HistoryEntry> history;
  final Unit unit;

  /// Called when a lift's card is tapped, to open its detail screen.
  final void Function(String exerciseId)? onOpenLift;

  @override
  State<ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<ProgressView> {
  ProgressRange _range = ProgressRange.sixMonths;
  _ChartTab _tab = _ChartTab.strength;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (widget.charts.isEmpty &&
        widget.bodyweight.isEmpty &&
        widget.history.isEmpty) {
      return EmptyState(
        loc.progressEmptyMessage,
        icon: Icons.insights_outlined,
      );
    }

    final now = DateTime.now();
    final summary = buildProgressSummary(
      history: widget.history,
      charts: widget.charts,
      bodyweight: widget.bodyweight,
      range: _range,
      now: now,
    );
    final records = buildPersonalRecords(widget.charts);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        SegmentedButton<ProgressRange>(
          segments: [
            ButtonSegment(
              value: ProgressRange.oneMonth,
              label: Text(loc.progressRangeOneMonth),
            ),
            ButtonSegment(
              value: ProgressRange.threeMonths,
              label: Text(loc.progressRangeThreeMonths),
            ),
            ButtonSegment(
              value: ProgressRange.sixMonths,
              label: Text(loc.progressRangeSixMonths),
            ),
            ButtonSegment(
              value: ProgressRange.oneYear,
              label: Text(loc.progressRangeOneYear),
            ),
            ButtonSegment(
              value: ProgressRange.all,
              label: Text(loc.progressRangeAll),
            ),
          ],
          selected: {_range},
          showSelectedIcon: false,
          onSelectionChanged: (sel) => setState(() => _range = sel.first),
        ),
        _SectionHeader(loc.progressOverallTitle),
        _OverallStats(summary: summary, unit: widget.unit),
        _SectionHeader(loc.progressChartsTitle),
        SegmentedButton<_ChartTab>(
          segments: [
            ButtonSegment(
              value: _ChartTab.weight,
              label: Text(loc.bodyweightChartTitle),
            ),
            ButtonSegment(
              value: _ChartTab.strength,
              label: Text(loc.progressStatStrength),
            ),
            ButtonSegment(
              value: _ChartTab.volume,
              label: Text(loc.progressChartVolume),
            ),
          ],
          selected: {_tab},
          showSelectedIcon: false,
          onSelectionChanged: (sel) => setState(() => _tab = sel.first),
        ),
        const SizedBox(height: 12),
        ..._chartTabContent(loc, now),
        if (records.isNotEmpty) ...[
          _SectionHeader(loc.progressRecordsTitle),
          _RecordsCard(records: records, unit: widget.unit),
        ],
      ],
    );
  }

  /// Builds the content for the currently selected chart tab, each scoped to
  /// [_range]. Falls back to an inline empty message when this tab has no
  /// points within the range.
  List<Widget> _chartTabContent(AppLocalizations loc, DateTime now) {
    final rangeEmpty = EmptyState(
      loc.progressRangeEmptyMessage,
      icon: Icons.insights_outlined,
    );

    switch (_tab) {
      case _ChartTab.weight:
        final points = filterPointsByRange(widget.bodyweight, _range, now);
        if (points.isEmpty) return [rangeEmpty];
        return [
          _ChartCard(
            title: loc.bodyweightChartTitle,
            points: points,
            unit: widget.unit,
          ),
        ];

      case _ChartTab.strength:
        final filtered = [
          for (final chart in widget.charts)
            (
              chart: chart,
              points: filterPointsByRange(chart.points, _range, now),
            ),
        ]..removeWhere((c) => c.points.isEmpty);
        if (filtered.isEmpty) return [rangeEmpty];
        return [
          for (final c in filtered)
            _ChartCard(
              title: c.chart.name,
              points: c.points,
              unit: widget.unit,
              onTap: widget.onOpenLift == null
                  ? null
                  : () => widget.onOpenLift!(c.chart.exerciseId),
            ),
        ];

      case _ChartTab.volume:
        final historyInRange = filterHistoryByRange(
          widget.history,
          _range,
          now,
        );
        final points = buildVolumeSeries(historyInRange);
        if (points.isEmpty) return [rangeEmpty];
        return [
          _ChartCard(
            title: loc.progressChartVolume,
            points: points,
            unit: widget.unit,
          ),
        ];
    }
  }
}

/// An uppercase, tracked section label, matching the settings screen.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// The four "Overall" stat tiles: workouts, strength change, bodyweight
/// change, and total volume — all scoped to the selected range.
class _OverallStats extends StatelessWidget {
  const _OverallStats({required this.summary, required this.unit});

  final ProgressSummary summary;
  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final strength = summary.strengthChangePercent;
    final strengthValue = strength == null
        ? '—'
        : '${strength >= 0 ? '+' : ''}${strength.round()}%';

    final bwDelta = summary.bodyweightChangeKg;
    final bwValue = bwDelta == null
        ? '—'
        : '${bwDelta >= 0 ? '+' : ''}'
            '${formatWeight(displayWeight(bwDelta, unit))} ${unit.name}';

    final volume = NumberFormat.decimalPattern(locale)
        .format(displayWeight(summary.totalVolumeKg, unit).round());

    // A Column of two Rows rather than a fixed-aspect-ratio GridView: tile
    // height then follows its content (icon + value + label), so it never
    // overflows at narrow widths or larger text-scale settings.
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.fitness_center,
                value: '${summary.workoutCount}',
                label: loc.workoutsLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: strength == null
                    ? Icons.show_chart
                    : strength >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                value: strengthValue,
                label: loc.progressStatStrength,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.monitor_weight_outlined,
                value: bwValue,
                label: loc.bodyWeightLabel,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.local_fire_department,
                value: '$volume ${unit.name}',
                label: loc.totalVolumeLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = value == '—'
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: accent),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700, color: accent),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// The all-time personal-record list — independent of the range filter,
/// since a record set outside the selected window is still a record.
class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records, required this.unit});

  final List<PersonalRecord> records;
  final Unit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < records.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16),
            ListTile(
              leading: Icon(
                Icons.emoji_events_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(records[i].name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weightLabel(records[i].bestWeightKg, unit),
                    style: theme.textTheme.titleMedium,
                  ),
                  if (records[i].isRecent) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_upward,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.points,
    required this.unit,
    this.onTap,
  });

  final String title;
  final List<WeightPoint> points;
  final Unit unit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = displayWeight(points.last.weightKg, unit);
    final latestLabel = '${formatWeight(latest)} ${unit.name}';

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), displayWeight(points[i].weightKg, unit)),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  Text(
                    latestLabel,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: spots.length < 2
                    ? Center(
                        child: Text(
                          AppLocalizations.of(context)!.logMoreToSeeTrend,
                          style: theme.textTheme.bodySmall,
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: const LineTouchData(enabled: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              color: theme.colorScheme.primary,
                              barWidth: 2.5,
                              isCurved: true,
                              curveSmoothness: 0.25,
                              // Emphasise only the latest point.
                              dotData: FlDotData(
                                getDotPainter: (spot, pct, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: index == spots.length - 1 ? 4 : 0,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              // Soft area fill fading to nothing.
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0.24),
                                    theme.colorScheme.primary
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
