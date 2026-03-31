import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/admin/models/user_model.dart';

class UserRepository {
  final Dio _dio=ApiClient.instance.dio;

  Future<List<UserModel>> getUsers() async{
    final r=await _dio.get('/api/users');
    return (r.data as List).map((e)=>UserModel.fromJson(e)).toList();
  }

  Future<UserModel> createUser(Map<String,dynamic> body) async{
    final r=await _dio.post('/api/users',data: body);
    return UserModel.fromJson(r.data);
  }

  Future<UserModel> updateUser(int id,Map<String,dynamic> body) async{
    final r=await _dio.put('/api/users/$id',data:body);
    return UserModel.fromJson(r.data);
  }

  Future<void> deactivateUser(int id)=> _dio.delete('/api/users/$id');
}
