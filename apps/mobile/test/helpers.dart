import 'package:ehliyet_akademi/app/app.dart';
import 'package:ehliyet_akademi/core/storage/token_store.dart';
import 'package:ehliyet_akademi/data/auth/auth_api.dart';
import 'package:ehliyet_akademi/domain/auth/app_user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A fake AuthApi for tests — no network. Configurable success/failure.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.user, this.token, this.failMessage});
  AppUser? user;
  String? token;
  String? failMessage;
  int meCalls = 0;

  @override
  Future<AuthResult> login({required String email, required String password}) async =>
      _result(email);

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      _result(email, name: name);

  AuthResult _result(String email, {String name = 'Test'}) {
    if (failMessage != null) return AuthFailure(failMessage!);
    final u = AppUser(id: 'u1', email: email, name: name, role: 'user');
    return AuthSuccess(u, token ?? 'token123');
  }

  @override
  Future<AppUser?> me() async {
    meCalls++;
    return user;
  }

  @override
  Future<void> logout() async {}
}

/// Pump the full app with test-safe overrides (no platform channels / network).
Future<void> pumpApp(
  WidgetTester tester, {
  TokenStore? tokens,
  AuthApi? auth,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(tokens ?? MemoryTokenStore()),
        if (auth != null) authApiProvider.overrideWithValue(auth),
      ],
      child: const EhliyetAkademiApp(),
    ),
  );
  await tester.pumpAndSettle();
}
