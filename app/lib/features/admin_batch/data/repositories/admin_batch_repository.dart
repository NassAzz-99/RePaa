import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../reservation/data/models/batch_model.dart';

class AdminBatchRepository {
  final Dio _dio;
  AdminBatchRepository(this._dio);

  Future<List<BatchModel>> getAll() async {
    try {
      final res = await _dio.get('/admin/batches');
      final list = res.data['data'] as List;
      return list
          .map((e) => BatchModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<BatchModel> update({
    required int id,
    required String name,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    try {
      final res = await _dio.put('/admin/batches/$id', data: {
        'name': name,
        'start_time': startTime,
        'end_time': endTime,
        'is_active': isActive,
      });
      return BatchModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminBatchRepositoryProvider =
    Provider<AdminBatchRepository>((ref) {
  return AdminBatchRepository(ref.watch(dioProvider));
});

