import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityAlert {
  final int id;
  final String alertType;
  final String severity;
  final String? ip;
  final String? email;
  final String? detail;
  final DateTime firedAt;

  SecurityAlert({
    required this.id,
    required this.alertType,
    required this.severity,
    this.ip,
    this.email,
    this.detail,
    required this.firedAt,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> j) => SecurityAlert(
    id: j['id'],
    alertType: j['alert_type'],
    severity: j['severity'],
    ip: j['ip'],
    email: j['email'],
    detail: j['detail'],
    firedAt: DateTime.parse(j['fired_at']),
  );
}

class SecuritySummary {
  final String threatLevel;
  final String summaryText;
  final DateTime generatedAt;
  final List<SecurityAlert> activeAlerts;

  SecuritySummary({
    required this.threatLevel,
    required this.summaryText,
    required this.generatedAt,
    required this.activeAlerts,
  });

  factory SecuritySummary.fromJson(Map<String, dynamic> j) => SecuritySummary(
    threatLevel: j['threat_level'],
    summaryText: j['summary_text'],
    generatedAt: DateTime.parse(j['generated_at']),
    activeAlerts: (j['active_alerts'] as List)
        .map((e) => SecurityAlert.fromJson(e))
        .toList(),
  );
}

class SecurityRepository {
  final _dio = ApiClient.instance.dio;

  Future<SecuritySummary> getSummary() async {
    final r = await _dio.get('/api/analytics/security/summary');
    return SecuritySummary.fromJson(r.data);
  }
}

final securityRepositoryProvider = Provider((_) => SecurityRepository());
