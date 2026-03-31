import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/admin/models/role_model.dart';

class RoleRepository {
  final Dio _dio=ApiClient.instance.dio;

  Future <List<RoleModel>> getRoles() async{
    final r= await _dio.get('/api/roles');
    return (r.data as List).map((e)=>RoleModel.fromJson(e)).toList();
  }

  Future<RoleModel> createRole(Map<String,dynamic> body) async{
    final r=await _dio.post('/api/roles',data: body);
    return RoleModel.fromJson(r.data);
  }

  Future <RoleModel> updateRole(int id,Map<String,dynamic> body) async{
    final r=await _dio.put('/api/roles/$id',data: body);
    return RoleModel.fromJson(r.data);
  }

  Future<void> deleteRole(int id)=> _dio.delete('/api/roles/$id');
}
