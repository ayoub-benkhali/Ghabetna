import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<Map<String, dynamic>> getKpis() async {
    final r = await _dio.get('/api/analytics/kpis');
    return r.data as Map<String, dynamic>;
  }

  /// Monthly incident counts for a given [year].
  /// Returns [{month, total, critical, resolved}, ...] — up to 12 entries.
  Future<List<dynamic>> getMonthlyTrend({int? year}) async {
    final r = await _dio.get(
      '/api/analytics/daily',
      queryParameters: {if (year != null) 'year': year},
    );
    return r.data as List<dynamic>;
  }

  /// Top 3 agents ranked by number of incidents reported.
  Future<List<dynamic>> getTopAgents() async {
    final r = await _dio.get('/api/analytics/top-agents');
    return r.data as List<dynamic>;
  }

  Future<List<dynamic>> getByCategory() async {
    final r = await _dio.get('/api/analytics/by-category');
    return r.data as List<dynamic>;
  }

  /// Top 3 forests ranked by number of incidents reported.
  Future<List<dynamic>> getTopForests() async {
    final r = await _dio.get('/api/analytics/density');
    return r.data as List<dynamic>;
  }

  /// Incident counts grouped by day-of-week × hour-of-day.
  /// Returns [{dow, hour, total}, ...] — sparse (missing cells = 0).
  Future<List<dynamic>> getPeakHours() async {
    final r = await _dio.get('/api/analytics/peak-hours');
    return r.data as List<dynamic>;
  }
}

final analyticsRepositoryProvider = Provider((_) => AnalyticsRepository());
