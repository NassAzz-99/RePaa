import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_stat_model.dart';

class AdminDashboardRepository {
  final Dio _dio;
  AdminDashboardRepository(this._dio);

  Future<DashboardStatModel> getStats() async {
    try {
      final res = await _dio.get('/admin/dashboard');
      return DashboardStatModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> approveReservation(int id) async {
    try {
      await _dio.post('/admin/reservations/$id/approve');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> rejectReservation(int id, String? note) async {
    try {
      await _dio.post('/admin/reservations/$id/reject',
          data: {'admin_note': note ?? ''});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminDashboardRepositoryProvider =
    Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(ref.watch(dioProvider));
});

