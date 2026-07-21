import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/features/admin/providers/analytics_provider.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_app/features/admin/widgets/security_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Entity counts ──────────────────────────────────────────────────────
    final forests = ref.watch(forestsProvider);
    final users = ref.watch(usersProvider);
    final services = ref.watch(servicesProvider);

    // ── Analytics data ─────────────────────────────────────────────────────
    final currentYear = DateTime.now().year;
    final kpis = ref.watch(kpisProvider);
    final monthly = ref.watch(monthlyTrendProvider(currentYear));
    final topAgents = ref.watch(topAgentsProvider);
    final byCategory = ref.watch(byCategoryProvider);
    final topForests = ref.watch(topForestsProvider);
    final peakHours = ref.watch(peakHoursProvider);
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l.dashboard), actions: kAppBarActions),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════════════════════
            // SECTION 1 — Entity Overview
            // ══════════════════════════════════════════════════════════════
            Text(l.overview, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(l.realtimeData, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            const Divider(),

            // ── Row 1: Entity cards ────────────────────────────────────
            Row(
              children: [
                _EntityKpiCard(
                  icon: Icons.forest,
                  label: l.forests,
                  color: AppColors.primaryGreen,
                  value: forests.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, _) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.people,
                  label: l.users,
                  color: AppColors.info,
                  value: users.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, _) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.account_tree,
                  label: l.adminServices,
                  color: AppColors.warning,
                  value: services.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, _) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.map_outlined,
                  label: l.parcelles,
                  color: AppColors.teal,
                  value: forests.when(
                    data: (list) =>
                        '${list.fold(0, (sum, f) => sum + f.parcelleCount)}',
                    loading: () => '…',
                    error: (_, _) => '!',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // ── Row 2: Incident KPI cards ──────────────────────────────
            kpis.when(
              loading: () => Row(
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: Card(
                        child: const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              error: (e, _) => Text('${l.errorPrefix} $e'),
              data: (data) => Row(
                children: [
                  _EntityKpiCard(
                    icon: Icons.list_alt,
                    label: l.totalIncidents,
                    color: AppColors.info,
                    value: '${data['total']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.warning_amber,
                    label: l.critical,
                    color: AppColors.danger,
                    value: '${data['critical']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.check_circle_outline,
                    label: l.resolvedLabel,
                    color: AppColors.success,
                    value: '${data['resolved']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.hourglass_empty,
                    label: l.pending,
                    color: AppColors.warning,
                    value: '${data['pending']}',
                  ),
                ],
              ),
            ),

            // ══════════════════════════════════════════════════════════════
            // SECTION 2 — Incident Statistics
            // ══════════════════════════════════════════════════════════════
            const Divider(),
            const SizedBox(height: 36),
            // ── Monthly Line Chart ─────────────────────────────────────
            monthly.when(
              loading: () => const _ChartLoader(height: 240),
              error: (e, _) => Text('${l.errorPrefix} $e'),
              data: (data) => _MonthlyLineChart(data: data, year: currentYear),
            ),
            const SizedBox(height: 24),

            // ── Top 3 Agents + Top 3 Forests (side by side) ───────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: topAgents.when(
                    loading: () => const _ChartLoader(height: 180),
                    error: (e, _) => Text('${l.errorPrefix} $e'),
                    data: (data) => _HorizontalBarChart(
                      title: l.top3Agents,
                      subtitle: l.agentsSubtitle,
                      entries: data.map((d) {
                        final row = d as Map<String, dynamic>;
                        return _HBarEntry(
                          label: row['agent_name'] as String,
                          value: (row['total'] as num).toInt(),
                          sub: (row['resolved'] as num).toInt(),
                        );
                      }).toList(),
                      barColor: AppColors.info,
                      valueLabel: l.reportedLabel,
                      subLabel: l.resolvedLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: topForests.when(
                    loading: () => const _ChartLoader(height: 180),
                    error: (e, _) => Text('${l.errorPrefix} $e'),
                    data: (data) => _HorizontalBarChart(
                      title: l.top3Forests,
                      subtitle: l.forestsSubtitle,
                      entries: data.map((d) {
                        final row = d as Map<String, dynamic>;
                        return _HBarEntry(
                          label: row['forest_name'] as String,
                          value: (row['total'] as num).toInt(),
                          sub: (row['critical'] as num).toInt(),
                        );
                      }).toList(),
                      barColor: AppColors.primaryGreen,
                      valueLabel: l.incidentsLabel,
                      subLabel: l.criticalLabel,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Category Pie Chart ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: byCategory.when(
                    loading: () => const _ChartLoader(height: 240),
                    error: (e, _) => Text('${l.errorPrefix} $e'),
                    data: (data) => _CategoryPieChart(data: data),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: peakHours.when(
                    loading: () => const _ChartLoader(height: 240),
                    error: (e, _) => Text('${l.errorPrefix} $e'),
                    data: (data) => _PeakHoursHeatmap(data: data),
                  ),
                ),
              ],
            ),
            // ══════════════════════════════════════════════════════════════
            // SECTION — Security
            // ══════════════════════════════════════════════════════════════
            const SizedBox(height: 32),
            Text(l.securityTitle, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              l.securitySectionSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            const SecurityCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Entity KPI Card  (forests / users / services / parcelles / incidents)
// ══════════════════════════════════════════════════════════════════════════════

class _EntityKpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String value;
  const _EntityKpiCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 35),
              ),
              const SizedBox(width: 12),
              // Label (top) + number (bottom)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Monthly Line Chart
// ══════════════════════════════════════════════════════════════════════════════

class _MonthlyLineChart extends StatelessWidget {
  final List<dynamic> data;
  final int year;
  const _MonthlyLineChart({required this.data, required this.year});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final localeName = l.localeName;

    // Locale-aware 3-letter month abbreviations (Jan/جانفي etc.)
    final monthLabels = List.generate(
      12,
      (i) => DateFormat('MMM', localeName).format(DateTime(year, i + 1, 1)),
    );

    // Tooltip series names drawn from l10n
    final tooltipNames = [l.total, l.critical, l.resolved];

    final byMonth = <int, Map<String, dynamic>>{};
    for (final item in data) {
      final row = item as Map<String, dynamic>;
      byMonth[row['month'] as int] = row;
    }

    final totalSpots = <FlSpot>[];
    final criticalSpots = <FlSpot>[];
    final resolvedSpots = <FlSpot>[];

    for (var m = 1; m <= 12; m++) {
      final row = byMonth[m];
      final x = (m - 1).toDouble();
      totalSpots.add(FlSpot(x, (row?['total'] as num? ?? 0).toDouble()));
      criticalSpots.add(FlSpot(x, (row?['critical'] as num? ?? 0).toDouble()));
      resolvedSpots.add(FlSpot(x, (row?['resolved'] as num? ?? 0).toDouble()));
    }

    final maxY = totalSpots.map((s) => s.y).reduce(max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row with legend stacked on the top right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l.evolutionTitle(year),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(color: AppColors.info, label: l.total),
                    const SizedBox(height: 6),
                    _Legend(color: AppColors.danger, label: l.critical),
                    const SizedBox(height: 6),
                    _Legend(color: AppColors.primaryGreen, label: l.resolved),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: maxY > 0 ? maxY * 1.2 : 5,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY > 0
                        ? (maxY / 4).ceilToDouble()
                        : 1,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Colors.black12, strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (val, _) {
                          final idx = val.toInt();
                          if (idx < 0 || idx > 11) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              monthLabels[idx],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, _) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      bottom: BorderSide(color: Colors.black12),
                      left: BorderSide(color: Colors.black12),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        return LineTooltipItem(
                          '${tooltipNames[s.barIndex]}: ${s.y.toInt()}',
                          TextStyle(
                            color: s.bar.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    _line(
                      spots: totalSpots,
                      color: AppColors.info,
                      dotted: false,
                    ),
                    _line(
                      spots: criticalSpots,
                      color: AppColors.danger,
                      dotted: true,
                    ),
                    _line(
                      spots: resolvedSpots,
                      color: AppColors.primaryGreen,
                      dotted: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _line({
    required List<FlSpot> spots,
    required Color color,
    required bool dotted,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.35,
      color: color,
      barWidth: dotted ? 2 : 3,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
          radius: 3,
          color: color,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      dashArray: dotted ? [4, 3] : null,
      belowBarData: BarAreaData(
        show: !dotted,
        color: color.withValues(alpha: 0.07),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Horizontal Bar Chart  (agents & forests)
// ══════════════════════════════════════════════════════════════════════════════

class _HBarEntry {
  final String label;
  final int value;
  final int sub;
  const _HBarEntry({
    required this.label,
    required this.value,
    required this.sub,
  });
}

class _HorizontalBarChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_HBarEntry> entries;
  final Color barColor;
  final String valueLabel;
  final String subLabel;

  const _HorizontalBarChart({
    required this.title,
    required this.subtitle,
    required this.entries,
    required this.barColor,
    required this.valueLabel,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            l.noDataAvailable,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final maxVal = entries.map((e) => e.value).reduce(max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ...entries.asMap().entries.map((e) {
              final rank = e.key + 1;
              final entry = e.value;
              final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: barColor.withValues(
                              alpha: rank == 1 ? 1 : 0.55,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$rank',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value} $valueLabel',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: barColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LayoutBuilder(
                      builder: (context, constraints) => Stack(
                        children: [
                          Container(
                            height: 10,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: barColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOut,
                            height: 10,
                            width: constraints.maxWidth * ratio,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.sub} $subLabel',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Category Pie Chart
// ══════════════════════════════════════════════════════════════════════════════

class _CategoryPieChart extends StatelessWidget {
  final List<dynamic> data;
  const _CategoryPieChart({required this.data});

  static const _palette = [
    AppColors.danger,
    AppColors.warning,
    AppColors.info,
    AppColors.primaryGreen,
    AppColors.teal,
    AppColors.sage,
    Colors.purple,
  ];

  // Maps backend category keys to l10n strings
  String _categoryLabel(BuildContext context, String cat) {
    final l = context.l10n;
    switch (cat) {
      case 'feu':
        return l.typeIncendie;
      case 'coupe_illegale':
        return l.typeCoupeIllegale;
      case 'refuge_suspect':
        return l.typeRefugeSuspect;
      case 'trafic':
        return l.typeTrafic;
      case 'dechet':
        return l.typeDechet;
      case 'maladie':
        return l.typeMaladie;
      case 'autre':
        return l.typeAutre;
      default:
        return cat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    if (data.isEmpty) return const SizedBox.shrink();

    final sections = <PieChartSectionData>[];
    for (var i = 0; i < data.length; i++) {
      final row = data[i] as Map<String, dynamic>;
      final total = (row['total'] as num).toDouble();
      sections.add(
        PieChartSectionData(
          color: _palette[i % _palette.length],
          value: total,
          title: '$total',
          radius: 90,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.incidentsByCategory,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 0,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(data.length, (i) {
                final row = data[i] as Map<String, dynamic>;
                final cat = row['category'] as String;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _palette[i % _palette.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _categoryLabel(context, cat),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Peak Hours Heatmap
// ══════════════════════════════════════════════════════════════════════════════

class _PeakHoursHeatmap extends StatelessWidget {
  final List<dynamic> data;
  const _PeakHoursHeatmap({required this.data});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    // Locale-aware day abbreviations. dow=0 is Sunday.
    // DateTime(2024, 1, 7) was a Sunday, so adding dow gives the right weekday.
    final days = List.generate(
      7,
      (dow) => DateFormat('E', l.localeName).format(DateTime(2024, 1, 7 + dow)),
    );

    final Map<(int, int), int> counts = {};
    int maxCount = 1;

    for (final item in data) {
      final row = item as Map<String, dynamic>;
      final dow = (row['dow'] as num).toInt();
      final hour = (row['hour'] as num).toInt();
      final total = (row['total'] as num).toInt();
      counts[(dow, hour)] = total;
      if (total > maxCount) maxCount = total;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.incidentsPeakByHour,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              l.incidentsByDayAndHour,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 36),
                Expanded(
                  child: Row(
                    children: List.generate(
                      24,
                      (h) => Expanded(
                        child: Text(
                          h % 3 == 0 ? '$h' : '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...List.generate(
              7,
              (dow) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 36,
                      child: Text(
                        days[dow],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(24, (hour) {
                          final count = counts[(dow, hour)] ?? 0;
                          final intensity = count / maxCount;
                          return Expanded(
                            child: Tooltip(
                              message:
                                  '${days[dow]} ${hour.toString().padLeft(2, '0')}h: $count ${l.incidents.toLowerCase()}',
                              child: Container(
                                height: 22,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: _cellColor(intensity),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: count > 0
                                    ? Center(
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontSize: 6.5,
                                            fontWeight: FontWeight.w700,
                                            color: intensity > 0.5
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.legend,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(width: 6),
                ...List.generate(5, (i) {
                  final intensity = i / 4;
                  final lo = i == 0 ? 1 : ((i / 4) * maxCount).round();
                  final hi = (((i + 1) / 4) * maxCount).round().clamp(
                    0,
                    maxCount,
                  );
                  final label = i == 4 ? '$lo' : '$lo–$hi';
                  return Column(
                    children: [
                      Container(
                        width: 28,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: _cellColor(intensity == 0 ? 0.01 : intensity),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: const TextStyle(fontSize: 7, color: Colors.grey),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _cellColor(double t) {
    if (t == 0) return Colors.grey.withValues(alpha: 0.08);
    if (t < 0.5) {
      return Color.lerp(
        AppColors.success.withValues(alpha: 0.25),
        AppColors.warning,
        t * 2,
      )!;
    }
    return Color.lerp(AppColors.warning, AppColors.danger, (t - 0.5) * 2)!;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Shared helpers
// ══════════════════════════════════════════════════════════════════════════════

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 3,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class _ChartLoader extends StatelessWidget {
  final double height;
  const _ChartLoader({required this.height});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: CircularProgressIndicator()),
  );
}
