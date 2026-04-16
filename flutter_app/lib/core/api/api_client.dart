import 'package:dio/dio.dart';
import 'token_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Called when a token refresh fails → app must log the user out
  void Function()? onUnauthorized;

  late final Dio _dio = _build();

  Dio _build() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshToken = await TokenStorage.getRefreshToken();
            if (refreshToken != null) {
              try {
                // Use a clean Dio (no interceptor) to avoid infinite loop
                final refreshDio = Dio(
                  BaseOptions(baseUrl: AppConstants.apiBaseUrl),
                );
                final resp = await refreshDio.post(
                  '/api/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                final newToken = resp.data['access_token'] as String;
                await TokenStorage.saveTokens(newToken, refreshToken);
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final retryResp = await _dio.fetch(opts);
                return handler.resolve(retryResp);
              } catch (_) {
                await TokenStorage.clear();
                onUnauthorized?.call();
              }
            } else {
              //No refresh token at all
              await TokenStorage.clear();
              onUnauthorized?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );
    return dio;
  }

  Dio get dio => _dio;
}
