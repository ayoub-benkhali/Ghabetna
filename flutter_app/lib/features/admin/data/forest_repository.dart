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
    try {
      final r = await _dio.post('/api/forests', data: body);
      return ForestModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<ForestModel> updateForest(int id, Map<String, dynamic> body) async {
    try {
      final r = await _dio.put('/api/forests/$id', data: body);
      return ForestModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> deleteForest(int id) async {
    try {
      await _dio.delete('/api/forests/$id');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

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
    try {
      final r = await _dio.post('/api/forests/$forestId/parcelles', data: body);
      return ParcelleModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<ParcelleModel> updateParcelle(
    int forestId,
    int parcelleId,
    Map<String, dynamic> body,
  ) async {
    try {
      final r = await _dio.put(
        '/api/forests/$forestId/parcelles/$parcelleId',
        data: body,
      );
      return ParcelleModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> deleteParcelle(int forestId, int parcelleId) async {
    try {
      await _dio.delete('/api/forests/$forestId/parcelles/$parcelleId');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<ParcelleModel?> getParcelleFlatById(int parcelleId) async {
    try {
      final r = await _dio.get('/api/parcelles/$parcelleId');
      return ParcelleModel.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _parseError(e);
    }
  }

  // ── Error parsing ─────────────────────────────────────────────────────────

  Exception _parseError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    // Guard: only index into data when it is actually a Map (body might be a
    // plain String or null for network-level errors, which would crash with []).
    final detail = (data is Map) ? data['detail']?.toString() : null;

    if (status == 404) return Exception(detail ?? 'Ressource introuvable.');
    if (status == 422) {
      // Pass the server's detail through (e.g. "Parcelle Boundary must be
      // contained within the forest boundaries") so the user sees a meaningful
      // message instead of the generic fallback.
      return Exception(
        detail ?? 'Données invalides. Vérifiez les champs saisis.',
      );
    }
    if (detail != null) return Exception(detail);
    return Exception(
      'Une erreur inattendue s\'est produite (${status ?? 'réseau'}).',
    );
  }
}
