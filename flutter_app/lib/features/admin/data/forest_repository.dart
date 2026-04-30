import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/admin/models/forest_model.dart';
import 'package:flutter_app/features/admin/models/parcelle_model.dart';

class ForestRepository {
  final Dio _dio = ApiClient.instance.dio;

  // ── Forests ──────────────────────────────────────────────────────────────
  Future<List<ForestModel>> getForests() async {
    final r = await _dio.get('/api/forests');
    return (r.data as List).map((e) => ForestModel.fromJson(e)).toList();
  }

  Future<ForestModel> getForest(int id) async {
    final r = await _dio.get('/api/forests/$id');
    return ForestModel.fromJson(r.data);
  }

  Future<ForestModel> createForest(Map<String, dynamic> body) async {
    final r = await _dio.post('/api/forests', data: body);
    return ForestModel.fromJson(r.data);
  }

  Future<ForestModel> updateForest(int id, Map<String, dynamic> body) async {
    final r = await _dio.put('/api/forests/$id', data: body);
    return ForestModel.fromJson(r.data);
  }

  Future<void> deleteForest(int id) => _dio.delete('/api/forests/$id');

  // ── Parcelles ──────────────────────────────────────────────────────────────

  Future<List<ParcelleModel>> getParcelles(int forestId) async {
    final r = await _dio.get('/api/forests/$forestId/parcelles');
    return (r.data as List).map((e) => ParcelleModel.fromJson(e)).toList();
  }

  Future<ParcelleModel?> getParcelle(int forestId, int parcelleId) async {
    try {
      final r = await _dio.get('/api/forests/$forestId/parcelles/$parcelleId');
      return ParcelleModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  Future<ParcelleModel> createParcelle(
    int forestId,
    Map<String, dynamic> body,
  ) async {
    final r = await _dio.post('/api/forests/$forestId/parcelles', data: body);
    return ParcelleModel.fromJson(r.data);
  }

  Future<ParcelleModel> updateParcelle(
    int forestId,
    int parcelleId,
    Map<String, dynamic> body,
  ) async {
    final r = await _dio.put(
      '/api/forests/$forestId/parcelles/$parcelleId',
      data: body,
    );
    return ParcelleModel.fromJson(r.data);
  }

  Future<void> deleteParcelle(int forestId, int parcelleId) =>
      _dio.delete('/api/forests/$forestId/parcelles/$parcelleId');

  Future<ParcelleModel?> getParcelleFlatById(int parcelleId) async {
    try {
      final r = await _dio.get('/api/parcelles/$parcelleId');
      return ParcelleModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
