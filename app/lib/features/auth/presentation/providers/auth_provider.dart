import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/services/storage_service.dart';

// ── State ─────────────────────────────────────────────────

/// State auth: loading, authenticated, unauthenticated, error
enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final Map<String, List<String>>? fieldErrors; // error validasi 422

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.fieldErrors,
  });

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    Map<String, List<String>>? fieldErrors,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors,
    );
  }

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ── Notifier ─────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final StorageService _storage;

  AuthNotifier(this._repo, this._storage) : super(const AuthState()) {
    _init();
  }

  /// Cek token saat app pertama dibuka.
  Future<void> _init() async {
    final token = await _storage.getToken();
    if (token == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _repo.me();
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _storage.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, fieldErrors: null);
    try {
      final auth = await _repo.login(email: email, password: password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: auth.user,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        fieldErrors: e.errors,
      );
    }
  }

  Future<void> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null, fieldErrors: null);
    try {
      await _repo.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      // Setelah register, langsung login
      await login(email, password);
    } on ApiException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
        fieldErrors: e.errors,
      );
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  void clearError() {
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: null,
      fieldErrors: null,
    );
  }
}

/// Provider global auth – dipakai di seluruh app untuk cek status login dan role
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(authRepositoryProvider),
    ref.watch(storageServiceProvider),
  );
});
