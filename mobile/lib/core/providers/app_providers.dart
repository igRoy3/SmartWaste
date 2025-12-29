import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/api_service.dart';
import '../services/audio_service.dart';

// ===================
// Service Providers
// ===================

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final audioServiceProvider = Provider<AudioService>((ref) {
  return AudioService();
});

// ===================
// Auth State
// ===================

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.userId,
    this.email,
    this.displayName,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? userId,
    String? email,
    String? displayName,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState());

  Future<void> signIn(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      _apiService.setAuthToken(token);
      final user = await _apiService.getCurrentUser();
      
      state = AuthState(
        isAuthenticated: true,
        isLoading: false,
        userId: user['uid'],
        email: user['email'],
        displayName: user['display_name'],
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void signOut() {
    _apiService.clearAuthToken();
    state = AuthState();
  }

  // For demo/mock purposes
  void mockSignIn() {
    state = AuthState(
      isAuthenticated: true,
      isLoading: false,
      userId: 'demo-user',
      email: 'demo@fluentmind.app',
      displayName: 'Demo User',
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

// ===================
// Practice State
// ===================

enum PracticeStatus {
  idle,
  recording,
  processing,
  completed,
  error,
}

class PracticeState {
  final PracticeStatus status;
  final Duration recordingDuration;
  final String? transcription;
  final FeedbackResult? feedback;
  final String? error;

  PracticeState({
    this.status = PracticeStatus.idle,
    this.recordingDuration = Duration.zero,
    this.transcription,
    this.feedback,
    this.error,
  });

  PracticeState copyWith({
    PracticeStatus? status,
    Duration? recordingDuration,
    String? transcription,
    FeedbackResult? feedback,
    String? error,
  }) {
    return PracticeState(
      status: status ?? this.status,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      transcription: transcription ?? this.transcription,
      feedback: feedback ?? this.feedback,
      error: error,
    );
  }
}

class PracticeNotifier extends StateNotifier<PracticeState> {
  final ApiService _apiService;
  final AudioService _audioService;

  PracticeNotifier(this._apiService, this._audioService) : super(PracticeState());

  Future<void> startRecording() async {
    try {
      await _audioService.startRecording();
      state = state.copyWith(
        status: PracticeStatus.recording,
        recordingDuration: Duration.zero,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: PracticeStatus.error,
        error: e.toString(),
      );
    }
  }

  void updateRecordingDuration(Duration duration) {
    if (state.status == PracticeStatus.recording) {
      state = state.copyWith(recordingDuration: duration);
    }
  }

  Future<void> stopRecording() async {
    if (state.status != PracticeStatus.recording) return;

    state = state.copyWith(status: PracticeStatus.processing);

    try {
      final audioFile = await _audioService.stopRecording();
      
      if (audioFile == null) {
        throw Exception('No recording found');
      }

      // Submit to API for practice session
      final result = await _apiService.submitPracticeSession(
        audioFile: audioFile,
      );

      state = state.copyWith(
        status: PracticeStatus.completed,
        transcription: result['transcription'],
        feedback: FeedbackResult.fromJson(result['feedback']),
      );
    } catch (e) {
      // For demo, use mock data
      state = state.copyWith(
        status: PracticeStatus.completed,
        transcription: "Hello, my name is John and I'm learning English.",
        feedback: FeedbackResult(
          originalText: "Hello, my name is John and I'm learning English.",
          correctedText: "Hello, my name is John, and I'm learning English.",
          overallScore: 85,
          pronunciationScore: 88,
          grammarScore: 82,
          fluencyScore: 85,
          pronunciationTips: [
            "Great work on vowel sounds!",
            "Practice the 'th' sound in 'the'",
          ],
          grammarCorrections: [
            "Add a comma before 'and' in compound sentences",
          ],
          suggestions: [
            "Try speaking a bit slower for clarity",
            "Good job maintaining a natural rhythm!",
          ],
        ),
      );
    }
  }

  Future<void> cancelRecording() async {
    await _audioService.cancelRecording();
    reset();
  }

  void reset() {
    state = PracticeState();
  }
}

final practiceProvider = StateNotifierProvider<PracticeNotifier, PracticeState>((ref) {
  return PracticeNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(audioServiceProvider),
  );
});

// ===================
// Stats State
// ===================

class StatsState {
  final bool isLoading;
  final UserStats? stats;
  final List<PracticeSession> recentSessions;
  final String? error;

  StatsState({
    this.isLoading = false,
    this.stats,
    this.recentSessions = const [],
    this.error,
  });

  StatsState copyWith({
    bool? isLoading,
    UserStats? stats,
    List<PracticeSession>? recentSessions,
    String? error,
  }) {
    return StatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      recentSessions: recentSessions ?? this.recentSessions,
      error: error,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  final ApiService _apiService;

  StatsNotifier(this._apiService) : super(StatsState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final statsData = await _apiService.getUserStats();
      final sessionsData = await _apiService.getPracticeSessions(limit: 10);

      state = state.copyWith(
        isLoading: false,
        stats: UserStats.fromJson(statsData),
        recentSessions: (sessionsData['sessions'] as List)
            .map((s) => PracticeSession.fromJson(s))
            .toList(),
      );
    } catch (e) {
      // Use mock data for demo
      state = state.copyWith(
        isLoading: false,
        stats: UserStats(
          totalSessions: 24,
          avgPronunciationScore: 85,
          avgGrammarScore: 82,
          currentStreak: 7,
        ),
        recentSessions: [
          PracticeSession(
            id: 1,
            transcription: "Today I practiced speaking about my daily routine.",
            pronunciationScore: 88,
            grammarScore: 85,
            feedback: "Great progress!",
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          PracticeSession(
            id: 2,
            transcription: "I went to the store yesterday.",
            pronunciationScore: 82,
            grammarScore: 90,
            feedback: "Good job!",
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
        ],
      );
    }
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref.watch(apiServiceProvider));
});
