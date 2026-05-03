import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyAccess        = 'access_token';
  static const _keyRefresh       = 'refresh_token';
  static const _keyUserId        = 'user_id';
  static const _keyNeedsOnboard  = 'needs_onboarding';
  static const _keyUsername = 'username';
  static const _keyName     = 'user_name';

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
  Future<void> saveUserInfo({
    required String userId,
    required String username,
    required String name,
  }) async {
    await _storage.write(key: _keyUserId,   value: userId);
    await _storage.write(key: _keyUsername, value: username);
    await _storage.write(key: _keyName,     value: name);
  }

  Future<String?> getUsername() async =>
      _storage.read(key: _keyUsername);

  Future<String?> getName() async =>
      _storage.read(key: _keyName);

  // ── ONBOARDING ────────────────────────────────────────────
  Future<void> setNeedsOnboarding(bool value) async =>
      _storage.write(
          key: _keyNeedsOnboard, value: value.toString());

  Future<bool> getNeedsOnboarding() async {
    final val = await _storage.read(key: _keyNeedsOnboard);
    return val == 'true';
  }
}