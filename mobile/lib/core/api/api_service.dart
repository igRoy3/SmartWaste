import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/garbage_report.dart';
import '../config/app_config.dart';

class ApiService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _tokenKey = 'access_token';

  ApiService({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage() {
    _dio.options.baseUrl = AppConfig.apiBaseUrl;
    _dio.options.connectTimeout = AppConfig.connectTimeout;
    _dio.options.receiveTimeout = AppConfig.receiveTimeout;

    // Add interceptor to add auth token to requests
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Handle 401 errors (unauthorized)
          if (error.response?.statusCode == 401) {
            // Clear token and redirect to login
            clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Token management
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  // Authentication
  Future<AuthResponse> register({
    required String uid,
    String? email,
    String? name,
    String role = 'citizen',
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
      },
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await saveToken(authResponse.accessToken);
    return authResponse;
  }

  Future<AuthResponse> login({required String uid}) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'uid': uid},
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await saveToken(authResponse.accessToken);
    return authResponse;
  }

  Future<void> logout() async {
    await clearToken();
  }

  // Garbage Reports (Citizen)
  Future<GarbageReport> createReport({
    required double locationLat,
    required double locationLng,
    String? address,
    String? description,
    required String photoPath,
  }) async {
    final formData = FormData.fromMap({
      'location_lat': locationLat,
      'location_lng': locationLng,
      if (address != null) 'address': address,
      if (description != null) 'description': description,
      'photo': await MultipartFile.fromFile(
        photoPath,
        filename: photoPath.split('/').last,
      ),
    });

    final response = await _dio.post(
      '/reports',
      data: formData,
    );
    return GarbageReport.fromJson(response.data);
  }

  Future<List<GarbageReport>> getMyReports({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/reports',
      queryParameters: {
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => GarbageReport.fromJson(json))
        .toList();
  }

  Future<GarbageReport> getReport(int reportId) async {
    final response = await _dio.get('/reports/$reportId');
    return GarbageReport.fromJson(response.data);
  }

  // Admin endpoints
  Future<List<GarbageReport>> getAllReports({
    String? statusFilter,
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/admin/reports',
      queryParameters: {
        if (statusFilter != null) 'status_filter': statusFilter,
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => GarbageReport.fromJson(json))
        .toList();
  }

  Future<GarbageReport> assignReport({
    required int reportId,
    required int collectorId,
  }) async {
    final response = await _dio.put(
      '/admin/reports/$reportId/assign',
      data: {'collector_id': collectorId},
    );
    return GarbageReport.fromJson(response.data);
  }

  Future<List<Map<String, dynamic>>> getCollectors() async {
    final response = await _dio.get('/admin/collectors');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<AdminStats> getAdminStats() async {
    final response = await _dio.get('/admin/stats');
    return AdminStats.fromJson(response.data);
  }

  // Collector endpoints
  Future<List<GarbageReport>> getCollectorTasks({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/collector/tasks',
      queryParameters: {
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => GarbageReport.fromJson(json))
        .toList();
  }

  Future<GarbageReport> getTaskDetail(int taskId) async {
    final response = await _dio.get('/collector/tasks/$taskId');
    return GarbageReport.fromJson(response.data);
  }

  Future<GarbageReport> startTask(int taskId) async {
    final response = await _dio.put('/collector/tasks/$taskId/start');
    return GarbageReport.fromJson(response.data);
  }

  Future<GarbageReport> completeTask(int taskId) async {
    final response = await _dio.put('/collector/tasks/$taskId/complete');
    return GarbageReport.fromJson(response.data);
  }

  Future<List<GarbageReport>> getCompletedTasks({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await _dio.get(
      '/collector/history',
      queryParameters: {
        'skip': skip,
        'limit': limit,
      },
    );
    return (response.data as List)
        .map((json) => GarbageReport.fromJson(json))
        .toList();
  }
}
