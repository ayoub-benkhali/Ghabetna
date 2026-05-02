import 'package:flutter_app/features/admin/data/analytics_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsRepositoryProvider = Provider((_) => AnalyticsRepository());

final kpisProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(analyticsRepositoryProvider).getKpis(),
);

/// Monthly trend for a given year — drives the line chart.
final monthlyTrendProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>(
      (ref, year) =>
          ref.watch(analyticsRepositoryProvider).getMonthlyTrend(year: year),
    );

/// Top 3 agents by incident count — drives the horizontal bar chart.
final topAgentsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(analyticsRepositoryProvider).getTopAgents(),
);

final byCategoryProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(analyticsRepositoryProvider).getByCategory(),
);

/// Top 3 forests by incident count — drives the horizontal bar chart.
final topForestsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(analyticsRepositoryProvider).getTopForests(),
);

/// Peak incident hours — drives the heatmap grid.
final peakHoursProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(analyticsRepositoryProvider).getPeakHours(),
);
