import 'dart:math' show max;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/extensions/context_ext.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/core/widgets/app_bar_actions.dart';
import 'package:flutter_app/features/admin/providers/analytics_provider.dart';
import 'package:flutter_app/features/admin/providers/forest_provider.dart';
import 'package:flutter_app/features/admin/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dashboard),
        actions: kAppBarActions,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════════════════════════════
            // SECTION 1 — Entity Overview
            // ══════════════════════════════════════════════════════════════
            Text(
              context.l10n.overview,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.realtimeData,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            const Divider(),

            // ── Row 1: Entity cards ────────────────────────────────────
            Row(
              children: [
                _EntityKpiCard(
                  icon: Icons.forest,
                  label: context.l10n.forests,
                  color: AppColors.primaryGreen,
                  value: forests.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.people,
                  label: context.l10n.users,
                  color: AppColors.info,
                  value: users.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.account_tree,
                  label: context.l10n.services,
                  color: AppColors.warning,
                  value: services.when(
                    data: (d) => '${d.length}',
                    loading: () => '…',
                    error: (_, __) => '!',
                  ),
                ),
                const SizedBox(width: 2),
                _EntityKpiCard(
                  icon: Icons.map_outlined,
                  label: context.l10n.parcelles,
                  color: AppColors.teal,
                  value: forests.when(
                    data: (list) =>
                        '${list.fold(0, (sum, f) => sum + f.parcelleCount)}',
                    loading: () => '…',
                    error: (_, __) => '!',
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
              error: (e, _) => Text('Erreur: $e'),
              data: (data) => Row(
                children: [
                  _EntityKpiCard(
                    icon: Icons.list_alt,
                    label: 'Total incidents',
                    color: AppColors.info,
                    value: '${data['total']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.warning_amber,
                    label: 'Critiques',
                    color: AppColors.danger,
                    value: '${data['critical']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.check_circle_outline,
                    label: 'Traités',
                    color: AppColors.success,
                    value: '${data['resolved']}',
                  ),
                  const SizedBox(width: 2),
                  _EntityKpiCard(
                    icon: Icons.hourglass_empty,
                    label: 'En attente',
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
              error: (e, _) => Text('Erreur: $e'),
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
                    error: (e, _) => Text('Erreur: $e'),
                    data: (data) => _HorizontalBarChart(
                      title: 'Top 3 agents',
                      subtitle: 'Incidents signalés',
                      entries: data.map((d) {
                        final row = d as Map<String, dynamic>;
                        return _HBarEntry(
                          label: row['agent_name'] as String,
                          value: (row['total'] as num).toInt(),
                          sub: (row['resolved'] as num).toInt(),
                        );
                      }).toList(),
                      barColor: AppColors.info,
                      valueLabel: 'signalés',
                      subLabel: 'résolus',
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Expanded(
                  child: topForests.when(
                    loading: () => const _ChartLoader(height: 180),
                    error: (e, _) => Text('Erreur: $e'),
                    data: (data) => _HorizontalBarChart(
                      title: 'Top 3 forêts',
                      subtitle: 'Incidents par forêt',
                      entries: data.map((d) {
                        final row = d as Map<String, dynamic>;
                        return _HBarEntry(
                          label: row['forest_name'] as String,
                          value: (row['total'] as num).toInt(),
                          sub: (row['critical'] as num).toInt(),
                        );
                      }).toList(),
                      barColor: AppColors.primaryGreen,
                      valueLabel: 'incidents',
                      subLabel: 'critiques',
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
                    error: (e, _) => Text('$e'),
                    data: (data) => _CategoryPieChart(data: data),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: peakHours.when(
                    loading: () => const _ChartLoader(height: 240),
                    error: (e, _) => Text('Erreur: $e'),
                    data: (data) => _PeakHoursHeatmap(data: data),
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

  static const _monthLabels = [
    'Jan',
    'Fév',
    'Mar',
    'Avr',
    'Mai',
    'Jui',
    'Jul',
    'Aoû',
    'Sep',
    'Oct',
    'Nov',
    'Déc',
  ];

  @override
  Widget build(BuildContext context) {
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
                    'Évolution des incidents en $year',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _Legend(color: AppColors.info, label: 'Total'),
                    SizedBox(height: 6),
                    _Legend(color: AppColors.danger, label: 'Critiques'),
                    SizedBox(height: 6),
                    _Legend(color: AppColors.primaryGreen, label: 'Résolus'),
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
                              _monthLabels[idx],
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
                        const names = ['Total', 'Critiques', 'Résolus'];
                        return LineTooltipItem(
                          '${names[s.barIndex]}: ${s.y.toInt()}',
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
        getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
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
    if (entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Aucune donnée disponible.',
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

  static const _labels = {
    'feu': 'Feu',
    'coupe_illegale': 'Coupe illégale',
    'refuge_suspect': 'Refuge suspect',
    'trafic': 'Trafic',
    'dechet': 'Déchet',
    'maladie': 'Maladie',
    'autre': 'Autre',
  };

  @override
  Widget build(BuildContext context) {
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
              'Nombre d\'incidents par catégorie',
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
                      _labels[cat] ?? cat,
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

class _PeakHoursHeatmap extends StatelessWidget {
  final List<dynamic> data;
  const _PeakHoursHeatmap({required this.data});

  static const _days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

  @override
  Widget build(BuildContext context) {
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
              'Pic d\'incidents par heure',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Nombre d\'incidents signalés par jour et heure',
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
                        _days[dow],
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
                                  '${_days[dow]} ${hour.toString().padLeft(2, '0')}h: $count incident${count > 1 ? 's' : ''}',
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
                const Text(
                  'Légende :',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
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
