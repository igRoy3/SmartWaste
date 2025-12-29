import 'dart:io';
import 'package:dio/dio.dart';

import '../config/app_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late final Dio _dio;
  String? _authToken;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and token handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          print('API Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('API Response: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (error, handler) {
          print('API Error: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // ===================
  // Auth Endpoints
  // ===================
  
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/api/v1/users/me');
    return response.data;
  }

  // ===================
  // Speech Endpoints
  // ===================

  Future<Map<String, dynamic>> transcribeAudio(File audioFile) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.m4a',
      ),
    });

    final response = await _dio.post(
      '/api/v1/speech/transcribe',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    
    return response.data;
  }

  Future<Map<String, dynamic>> getAIFeedback({
    required String text,
    String targetLanguage = 'en',
  }) async {
    final response = await _dio.post(
      '/api/v1/speech/feedback',
      data: {
        'text': text,
        'target_language': targetLanguage,
      },
    );
    
    return response.data;
  }

  Future<Map<String, dynamic>> submitPracticeSession({
    required File audioFile,
    String? targetLanguage,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        audioFile.path,
        filename: 'recording.m4a',
      ),
      if (targetLanguage != null) 'target_language': targetLanguage,
    });

    final response = await _dio.post(
      '/api/v1/speech/practice',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );
    
    return response.data;
  }

  // ===================
  // User Stats Endpoints
  // ===================

  Future<Map<String, dynamic>> getUserStats() async {
    final response = await _dio.get('/api/v1/users/me/stats');
    return response.data;
  }

  Future<Map<String, dynamic>> getPracticeSessions({
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      '/api/v1/users/me/sessions',
      queryParameters: {
        'skip': skip,
        'limit': limit,
      },
    );
    return response.data;
  }
}

// Models
class TranscriptionResult {
  final String text;

  TranscriptionResult({required this.text});

  factory TranscriptionResult.fromJson(Map<String, dynamic> json) {
    return TranscriptionResult(text: json['text'] ?? '');
  }
}

class FeedbackResult {
  final String originalText;
  final String correctedText;
  final double overallScore;
  final double pronunciationScore;
  final double grammarScore;
  final double fluencyScore;
  final List<String> pronunciationTips;
  final List<String> grammarCorrections;
  final List<String> suggestions;

  FeedbackResult({
    required this.originalText,
    required this.correctedText,
    required this.overallScore,
    required this.pronunciationScore,
    required this.grammarScore,
    required this.fluencyScore,
    required this.pronunciationTips,
    required this.grammarCorrections,
    required this.suggestions,
  });

  factory FeedbackResult.fromJson(Map<String, dynamic> json) {
    return FeedbackResult(
      originalText: json['original_text'] ?? '',
      correctedText: json['corrected_text'] ?? '',
      overallScore: (json['overall_score'] ?? 0).toDouble(),
      pronunciationScore: (json['pronunciation_score'] ?? 0).toDouble(),
      grammarScore: (json['grammar_score'] ?? 0).toDouble(),
      fluencyScore: (json['fluency_score'] ?? 0).toDouble(),
      pronunciationTips: List<String>.from(json['pronunciation_tips'] ?? []),
      grammarCorrections: List<String>.from(json['grammar_corrections'] ?? []),
      suggestions: List<String>.from(json['suggestions'] ?? []),
    );
  }
}

class PracticeSession {
  final int id;
  final String transcription;
  final double pronunciationScore;
  final double grammarScore;
  final String feedback;
  final DateTime createdAt;

  PracticeSession({
    required this.id,
    required this.transcription,
    required this.pronunciationScore,
    required this.grammarScore,
    required this.feedback,
    required this.createdAt,
  });

  factory PracticeSession.fromJson(Map<String, dynamic> json) {
    return PracticeSession(
      id: json['id'],
      transcription: json['transcription'] ?? '',
      pronunciationScore: (json['pronunciation_score'] ?? 0).toDouble(),
      grammarScore: (json['grammar_score'] ?? 0).toDouble(),
      feedback: json['feedback'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserStats {
  final int totalSessions;
  final double avgPronunciationScore;
  final double avgGrammarScore;
  final int currentStreak;

  UserStats({
    required this.totalSessions,
    required this.avgPronunciationScore,
    required this.avgGrammarScore,
    required this.currentStreak,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalSessions: json['total_sessions'] ?? 0,
      avgPronunciationScore: (json['avg_pronunciation_score'] ?? 0).toDouble(),
      avgGrammarScore: (json['avg_grammar_score'] ?? 0).toDouble(),
      currentStreak: json['current_streak'] ?? 0,
    );
  }
}
