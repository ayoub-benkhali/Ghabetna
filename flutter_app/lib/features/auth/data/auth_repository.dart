import 'package:dio/dio.dart';
import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/core/api/token_storage.dart';
import 'package:flutter_app/core/models/auth_user.dart';

class AuthRepository{
  final Dio _dio=ApiClient.instance.dio;

  //login -> returns AuthUser (parses JWT + fetches /auth/me for full name)
  Future<AuthUser> login(String email,String password) async{
    try {
      final resp=await _dio.post('/api/auth/login',data: {
        'email':email,
        'password':password
      });
      final access=resp.data['access_token'] as String;
      final refresh=resp.data['refresh_token'] as String;
      await TokenStorage.saveTokens(access, refresh);

      //fetch full user profile to get name, role name and serviceId
      final meResp=await _dio.get('/api/users/me');
      final userData=meResp.data as Map<String,dynamic>;

      return AuthUser.fromToken(access, 
      email: email, 
      fullName: userData['full_name'] as String, 
      roleName: userData['role']['name'] as String,
      serviceId: userData['service_id'] as int?
      );
    } on DioException catch (e) {
      throw _parseError(e);
    }
  }
  ///Activate account (first login with token from email)
  Future<void> activateAccount(String token,String password) async{
    try{
      await _dio.post('/api/auth/activate',data: {
        'token':token,
        'password':password
      });
    }on DioException catch (e){
      throw _parseError(e);
    }
  }

  ///Logout clears tokens
  Future<void> logout() async{
    try{
      final refresh=await TokenStorage.getRefreshToken();
      if(refresh!=null){
        await _dio.post('/api/auth/logout',data: {'refresh_token':refresh});
      }
    }catch(_){

    }finally{
      await TokenStorage.clear();
    }
  }

  ///Try to restore session from stored tokens
  Future<AuthUser?> restoreSession() async{
    final hasToken=await TokenStorage.hasToken();
    if(!hasToken) return null;
    try {
      final meResp=await _dio.get('/api/users/me');
      final userData=meResp.data as Map<String,dynamic>;
      final access=await TokenStorage.getAccessToken();
      return AuthUser.fromToken(
      access!, 
      email: userData['email'] as String, 
      fullName: userData['full_name'] as String, 
      roleName: userData['role']['name'] as String,
      serviceId: userData['service_id'] as int?
      );
    } catch (_) {
      await TokenStorage.clear();
      return null;
    }
  }

  String _parseError(DioException e){
    final status=e.response?.statusCode;
    final detail=e.response?.data?['detail'];
    if(status==401) return 'Email ou mot de passe incorrect';
    if(status==403) return 'Accès refusé';
    if(status==404) return 'Utilisateur introuvable';
    if(detail!=null) return detail.toString();
    return 'Erreur de connexion. Vérifiez votre réseau.';
  }
}
