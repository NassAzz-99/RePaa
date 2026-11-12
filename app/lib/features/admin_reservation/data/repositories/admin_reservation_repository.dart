import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reservation/data/models/reservation_model.dart';

class AdminReservationRepository {
  final Dio _dio;
  AdminReservationRepository(this._dio);

  Future<List<ReservationModel>> getAll({
    String? status,
    String? date,
    String? workUnit,
    int page = 1,
  }) async {
    try {
      final params = <String, dynamic>{'page': page};
      if (status != null && status != 'all') params['status'] = status;
      if (date != null && date.isNotEmpty) params['date'] = date;
      if (workUnit != null && workUnit.isNotEmpty) params['work_unit'] = workUnit;

      final res = await _dio.get('/admin/reservations', queryParameters: params);
      final list = res.data['data'] as List;
      return list
          .map((e) => ReservationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> approve(int id) async {
    try {
      await _dio.post('/admin/reservations/$id/approve');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reject(int id, String? note) async {
    try {
      await _dio.post('/admin/reservations/$id/reject',
          data: {'admin_note': note ?? ''});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> complete(int id) async {
    try {
      await _dio.post('/admin/reservations/$id/complete');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminReservationRepositoryProvider =
    Provider<AdminReservationRepository>((ref) {
  return AdminReservationRepository(ref.watch(dioProvider));
});

