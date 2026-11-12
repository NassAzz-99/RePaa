import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_user_model.dart';

class AdminUserRepository {
  final Dio _dio;
  AdminUserRepository(this._dio);

  Future<List<AdminUserModel>> getAll() async {
    try {
      final res = await _dio.get('/admin/users');
      final list = res.data['data'] as List;
      return list
          .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AdminUserModel> setRole(int id, String role) async {
    try {
      final res = await _dio.patch('/admin/users/$id/role', data: {'role': role});
      return AdminUserModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AdminUserModel> setActive(int id, bool isActive) async {
    try {
      final res = await _dio.patch('/admin/users/$id/active',
          data: {'is_active': isActive});
      return AdminUserModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminUserRepositoryProvider =
    Provider<AdminUserRepository>((ref) {
  return AdminUserRepository(ref.watch(dioProvider));
});

