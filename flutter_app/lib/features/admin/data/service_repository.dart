import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/features/admin/models/service_model.dart';

class ServiceRepository {
  final Dio _dio=ApiClient.instance.dio;
  
  Future<List<ServiceModel>> getServices()async{
    final r=await _dio.get('/api/services');
    return (r.data as List).map((e)=>ServiceModel.fromJson(e)).toList();
  }

  Future<ServiceModel> createService(Map<String,dynamic> body) async{
    final r=await _dio.post('/api/services',data: body);
    return ServiceModel.fromJson(r.data);
  }

  Future<ServiceModel> updateService(int id,Map<String,dynamic> body) async{
    final r=await _dio.put('/api/services/$id',data: body);
    return ServiceModel.fromJson(r.data);
  }

  Future<void> deleteService(int id)=> _dio.delete('/api/services/$id');
}
