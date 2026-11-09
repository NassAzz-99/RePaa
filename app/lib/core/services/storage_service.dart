import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/storage_keys.dart';

/// Wrapper untuk flutter_secure_storage.
/// Menyimpan token JWT dan data sesi di penyimpanan aman perangkat.
class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Token ────────────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: StorageKeys.accessToken);
  }

  // ── User Role ────────────────────────────────────────────

  Future<void> saveRole(String role) async {
    await _storage.write(key: StorageKeys.userRole, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: StorageKeys.userRole);
  }

  // ── Semua sesi ───────────────────────────────────────────

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

/// Provider global StorageService.
final storageServiceProvider = Provider<StorageService>(
  (_) => StorageService(),
);
