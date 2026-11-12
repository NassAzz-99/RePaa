import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/report_model.dart';

class AdminReportRepository {
  final Dio _dio;
  AdminReportRepository(this._dio);

  Future<ReportModel> getReport({
    required String period, // 'daily' | 'weekly'
    required String startDate, // 'YYYY-MM-DD'
  }) async {
    try {
      final res = await _dio.get('/admin/reports',
          queryParameters: {'period': period, 'start_date': startDate});
      return ReportModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminReportRepositoryProvider =
    Provider<AdminReportRepository>((ref) {
  return AdminReportRepository(ref.watch(dioProvider));
});

