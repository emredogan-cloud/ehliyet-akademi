import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/token_store.dart';
import '../../data/auth/auth_api.dart';
import 'app_user.dart';

enum AuthStatus { unknown, guest, authenticated }

@immutable
class AuthState {
  const AuthState(this.status, [this.user]);
  final AuthStatus status;
  final AppUser? user;

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;

  static const unknown = AuthState(AuthStatus.unknown);
  static const guest = AuthState(AuthStatus.guest);
}

/// Owns the session: resolves the stored token on startup, and handles login/register/logout.
/// The app never gates on auth — guests use everything; auth adds identity + sync.
class AuthController extends Notifier<AuthState> {
  AuthApi get _api => ref.read(authApiProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  AuthState build() {
    // Resolve asynchronously without blocking the UI (shell renders immediately).
    Future.microtask(_resolve);
    return AuthState.unknown;
  }

  Future<void> _resolve() async {
    final token = await _tokens.read();
    if (token == null || token.isEmpty) {
      state = AuthState.guest;
      return;
    }
    final user = await _api.me();
    if (user != null) {
      state = AuthState(AuthStatus.authenticated, user);
    } else {
      await _tokens.clear();
      state = AuthState.guest;
    }
  }

  /// Returns null on success, or an error message.
  Future<String?> login({required String email, required String password}) async {
    final r = await _api.login(email: email, password: password);
    return _apply(r);
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final r = await _api.register(name: name, email: email, password: password);
    return _apply(r);
  }

  Future<String?> _apply(AuthResult r) async {
    switch (r) {
      case AuthSuccess(:final user, :final token):
        await _tokens.write(token);
        state = AuthState(AuthStatus.authenticated, user);
        return null;
      case AuthFailure(:final message):
        return message;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    await _tokens.clear();
    state = AuthState.guest;
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
