class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  // For Android emulator, use: 'http://10.0.2.2:8000/api/v1'
  // For iOS simulator, use: 'http://localhost:8000/api/v1'
  // For real device, use your server's IP or domain

  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // File upload
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  /// Get full URL for uploaded images
  static String getImageUrl(String photoUrl) {
    // If photoUrl is already a full URL, return it
    if (photoUrl.startsWith('http')) {
      return photoUrl;
    }

    // Otherwise, construct the full URL
    final baseUrl = apiBaseUrl.replaceAll('/api/v1', '');
    return '$baseUrl$photoUrl';
  }
}
