import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_service.dart';
import '../../core/models/user.dart';

// API Service Provider
final apiServiceProvider = Provider((ref) => ApiService());

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState());

  Future<void> register({
    required String uid,
    String? email,
    String? name,
    String role = 'citizen',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.register(
        uid: uid,
        email: email,
        name: name,
        role: role,
      );
      state = state.copyWith(user: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> login({required String uid}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.login(uid: uid);
      state = state.copyWith(user: response.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    state = AuthState();
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(apiServiceProvider));
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

// Is Authenticated Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user != null;
});
