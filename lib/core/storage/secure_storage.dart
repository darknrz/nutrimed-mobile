import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccess        = 'access_token';
  static const _keyRefresh       = 'refresh_token';
  static const _keyUserId        = 'user_id';
  static const _keyNeedsOnboard  = 'needs_onboarding';

  // ── TOKENS ───────────────────────────────────────────────
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: _keyAccess,  value: access);
    await _storage.write(key: _keyRefresh, value: refresh);
  }

  Future<String?> getAccessToken()  async =>
      _storage.read(key: _keyAccess);

  Future<String?> getRefreshToken() async =>
      _storage.read(key: _keyRefresh);

  Future<void> clearTokens() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async =>
      (await getAccessToken()) != null;

  // ── USER ID ───────────────────────────────────────────────
  Future<void> saveUserId(String userId) async =>
      _storage.write(key: _keyUserId, value: userId);

  Future<String?> getUserId() async =>
      _storage.read(key: _keyUserId);

  // ── ONBOARDING ────────────────────────────────────────────
  Future<void> setNeedsOnboarding(bool value) async =>
      _storage.write(
          key: _keyNeedsOnboard, value: value.toString());

  Future<bool> getNeedsOnboarding() async {
    final val = await _storage.read(key: _keyNeedsOnboard);
    return val == 'true';
  }
}