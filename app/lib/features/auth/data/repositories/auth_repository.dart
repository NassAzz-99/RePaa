import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage_service.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

/// Repository Auth – semua komunikasi ke endpoint /auth/* dan /profile/*
/// Endpoint sesuai blueprint:
///   POST /auth/register
///   POST /auth/login
///   POST /auth/logout
///   GET  /auth/me
class AuthRepository {
  final Dio _dio;
  final StorageService _storage;

  AuthRepository(this._dio, this._storage);

  // ── Register ─────────────────────────────────────────────

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Login ─────────────────────────────────────────────────

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final auth = AuthResponseModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
      // Simpan token dan role ke secure storage
      await _storage.saveToken(auth.token);
      await _storage.saveRole(auth.user.role);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  // ── Logout ────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException {
      // Abaikan error logout – hapus token lokal tetap dilakukan
    } finally {
      await _storage.clearAll();
    }
  }

  // ── Me ────────────────────────────────────────────────────

  Future<UserModel> me() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(storageServiceProvider),
  );
});
