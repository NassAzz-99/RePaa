import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/vehicle_availability_model.dart';

/// Repository Dashboard.
/// Endpoint: GET /vehicles/availability?date=YYYY-MM-DD
class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<VehicleAvailabilityModel> getAvailability({String? date}) async {
    try {
      final queryParams = date != null ? {'date': date} : <String, dynamic>{};
      final response = await _dio.get(
        '/vehicles/availability',
        queryParameters: queryParams,
      );
      return VehicleAvailabilityModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
