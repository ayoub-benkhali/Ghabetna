import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';

class AssignmentRepository {
  final Dio _dio = ApiClient.instance.dio;

  // ── Agent ↔ Parcelle ────────────────────────────────────────────────────

  Future<void> assignAgentToParcelle(int userId, int parcelleId) async {
    await _dio.post(
      '/api/assignments/users/$userId',
      data: {'parcelle_id': parcelleId},
    );
  }

  Future<void> unassignAgent(int userId) async {
    await _dio.delete('/api/assignments/users/$userId');
  }

  // ── Supervisor ↔ Forest ─────────────────────────────────────────────────

  Future<void> assignSupervisorToForest(int userId, int forestId) async {
    await _dio.post(
      '/api/assignments/supervisors/$userId',
      data: {'forest_id': forestId},
    );
  }

  Future<void> unassignSupervisor(int userId) async {
    await _dio.delete('/api/assignments/supervisors/$userId');
  }
}
