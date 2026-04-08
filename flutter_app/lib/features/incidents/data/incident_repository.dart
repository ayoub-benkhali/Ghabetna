import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/incidents/models/incident_model.dart';

class IncidentRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<IncidentModel> createIncident({
    required String category,
    required String description,
    double? latitude,
    double? longitude,
    int? parcelleId,
    int? forestId,
    File? imageFile,
  }) async {
    final formData = FormData.fromMap({
      'category': category,
      'description': description,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (parcelleId != null) 'parcelle_id': parcelleId.toString(),
      if (forestId != null) 'forest_id': forestId.toString(),
      if (imageFile != null)
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
    });
    try {
      final resp = await _dio.post(
        '/api/incidents',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return IncidentModel.fromJson(resp.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ?? 'Failed to create incident',
      );
    }
  }

  Future<List<IncidentModel>> getMyIncidents() async {
    try {
      final resp = await _dio.get('/api/incidents/mine');
      return (resp.data as List)
          .map((j) => IncidentModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['detail'] ?? 'Failed to load incidents',
      );
    }
  }
}
