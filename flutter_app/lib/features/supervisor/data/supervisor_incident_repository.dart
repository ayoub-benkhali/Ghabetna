import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';

class SupervisorIncidentRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<IncidentModel>> getAllIncidents({
    String? status,
    String? category,
    int? forestId,
    int? parcelleId,
  }) async {
    final resp = await _dio.get(
      '/api/incidents',
      queryParameters: {
        'status': ?status,
        'category': ?category,
        'forest_id': ?forestId,
        'parcelle_id': ?parcelleId,
      },
    );
    return (resp.data as List)
        .map((j) => IncidentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<IncidentModel> updateStatus(
    int id,
    String status, {
    String? comment,
  }) async {
    final resp = await _dio.patch(
      '/api/incidents/$id',
      data: {
        'status': status,
        'supervisor_comment': ?comment,
      },
    );
    return IncidentModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<IncidentModel> getById(int id) async {
    final resp = await _dio.get('/api/incidents/$id');
    return IncidentModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
