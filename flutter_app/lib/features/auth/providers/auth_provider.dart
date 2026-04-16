import 'package:flutter_app/core/api/api_client.dart';
import 'package:flutter_app/core/models/auth_user.dart';
import 'package:flutter_app/features/auth/data/auth_repository.dart';
import 'package:flutter_app/features/shared/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (_) => AuthRepository(),
);

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final AuthUser? user;
  final String? error;

  const AuthState({required this.status, this.user, this.error});

  const AuthState.loading() : this(status: AuthStatus.loading);
  const AuthState.unauthenticated([String? error])
    : this(status: AuthStatus.unauthenticated, error: error);
  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AuthState.loading()) {
    ApiClient.instance.onUnauthorized = _forceLogout;
    _restore();
  }

  void _forceLogout() {
    if (!mounted) return;
    _ref.invalidate(myProfileProvider);
    state = const AuthState.unauthenticated();
  }

  Future<void> _restore() async {
    final user = await _repo.restoreSession();
    state = user != null
        ? AuthState.authenticated(user)
        : const AuthState.unauthenticated();
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState.loading();
    try {
      final user = await _repo.login(email, password);
      state = AuthState.authenticated(user);
      return true;
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _ref.invalidate(myProfileProvider);
    state = const AuthState.unauthenticated();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});

class LoginFromNotifier extends StateNotifier<AsyncValue<void>> {
  LoginFromNotifier() : super(const AsyncValue.data(null));

  void reset() => state = const AsyncValue.data(null);
  void setLoading() => state = const AsyncValue.loading();
  void setError(String msg) => state = AsyncValue.error(msg, StackTrace.empty);
}

final loginFormProvider =
    StateNotifierProvider.autoDispose<LoginFromNotifier, AsyncValue<void>>(
      (_) => LoginFromNotifier(),
    );
