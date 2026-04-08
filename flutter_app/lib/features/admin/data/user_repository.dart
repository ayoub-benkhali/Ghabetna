import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';

class UserRepository {
  final Dio _dio = ApiClient.instance.dio;

  Future<List<UserModel>> getUsers() async {
    final r = await _dio.get('/api/users');
    return (r.data as List).map((e) => UserModel.fromJson(e)).toList();
  }

  Future<UserModel> createUser(Map<String, dynamic> body) async {
    try {
      final r = await _dio.post('/api/users', data: body);
      return UserModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<UserModel> updateUser(int id, Map<String, dynamic> body) async {
    try {
      final r = await _dio.put('/api/users/$id', data: body);
      return UserModel.fromJson(r.data);
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Future<void> deactivateUser(int id) async {
    try {
      await _dio.delete('/api/users/$id');
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }

  Exception _parseError(DioException e) {
    final status = e.response?.statusCode;
    final detail = e.response?.data?['detail'];

    if (status == 409) {
      return Exception('Cet email est déjà utilisé par un autre compte.');
    }
    if (status == 404) {
      return Exception(detail ?? 'Ressource introuvable.');
    }
    if (status == 422) {
      return Exception('Données invalides. Vérifiez les champs saisis.');
    }
    if (detail != null) {
      return Exception(detail.toString());
    }
    return Exception(
      'Une erreur inattendue s\'est produite (${status ?? 'réseau'}).',
    );
  }
}
