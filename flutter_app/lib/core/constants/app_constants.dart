class AppConstants {
  AppConstants._();
  static const String apiBaseUrl=String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000'
    );
}
