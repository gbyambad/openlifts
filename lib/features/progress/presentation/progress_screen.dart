import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openlifts/core/database/tables.dart';
import 'package:openlifts/core/units/units.dart';
import 'package:openlifts/features/progress/application/progress_view.dart';
import 'package:openlifts/features/progress/domain/lift_chart.dart';
import 'package:openlifts/l10n/app_localizations.dart';
import 'package:openlifts/shared/widgets/async_view.dart';
import 'package:openlifts/shared/widgets/empty_state.dart';

/// Progress screen: a weight-over-time chart per trained lift, plus bodyweight.
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
          unit: d.unit,
          onOpenLift: (id) => context.push('/progress/exercises/$id'),
        ),
      ),
    );
  }
}

/// Pure, provider-free rendering of the progress charts.
class ProgressView extends StatelessWidget {
  const ProgressView({
    required this.charts,
    required this.bodyweight,
    required this.unit,
    this.onOpenLift,
    super.key,
  });

  final List<LiftChart> charts;
  final List<WeightPoint> bodyweight;
  final Unit unit;

  /// Called when a lift's card is tapped, to open its detail screen.
  final void Function(String exerciseId)? onOpenLift;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (charts.isEmpty && bodyweight.isEmpty) {
      return EmptyState(
        loc.progressEmptyMessage,
        icon: Icons.insights_outlined,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final chart in charts)
          _ChartCard(
            title: chart.name,
            points: chart.points,
            unit: unit,
            onTap:
                onOpenLift == null ? null : () => onOpenLift!(chart.exerciseId),
          ),
        if (bodyweight.isNotEmpty)
          _ChartCard(
            title: loc.bodyweightChartTitle,
            points: bodyweight,
            unit: unit,
          ),
      ],
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
