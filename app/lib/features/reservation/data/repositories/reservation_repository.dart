import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../models/available_vehicle_model.dart';
import '../models/batch_model.dart';
import '../models/reservation_model.dart';

/// Repository Reservasi.
/// Endpoints:
///   GET  /batches
///   GET  /vehicles/available?date=&batch_id=
///   GET  /work-units?q=
///   GET  /reservations
///   POST /reservations
///   GET  /reservations/:id
///   POST /reservations/:id/cancel
class ReservationRepository {
  final Dio _dio;

  ReservationRepository(this._dio);

  Future<List<BatchModel>> getBatches() async {
    try {
      final response = await _dio.get('/batches');
      final data = response.data['data'] as List;
      return data
          .map((b) => BatchModel.fromJson(b as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<AvailableVehicleModel>> getAvailableVehicles({
    required String date,
    required int batchId,
  }) async {
    try {
      final response = await _dio.get(
        '/vehicles/available',
        queryParameters: {'date': date, 'batch_id': batchId},
      );
      final data = response.data['data'] as List;
      return data
          .map((v) =>
              AvailableVehicleModel.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<String>> getWorkUnitSuggestions(String query) async {
    try {
      final response = await _dio.get(
        '/work-units',
        queryParameters: {'q': query},
      );
      final data = response.data['data'] as List;
      return data
          .map((wu) => (wu as Map<String, dynamic>)['name'] as String)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApiResponse<ReservationModel>> createReservation({
    required int vehicleId,
    required int batchId,
    required String reservationDate,
    required String workUnit,
    required String purpose,
  }) async {
    try {
      final response = await _dio.post('/reservations', data: {
        'vehicle_id': vehicleId,
        'batch_id': batchId,
        'reservation_date': reservationDate,
        'work_unit': workUnit,
        'purpose': purpose,
      });
      return ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => ReservationModel.fromJson(data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<ReservationModel>> getMyReservations({int page = 1}) async {
    try {
      final response = await _dio.get(
        '/reservations',
        queryParameters: {'page': page},
      );
      final data = (response.data['data'] as List?) ?? [];
      return data
          .map((r) =>
              ReservationModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ReservationModel> getReservationDetail(int id) async {
    try {
      final response = await _dio.get('/reservations/$id');
      return ReservationModel.fromJson(
          Map<String, dynamic>.from(response.data['data'] as Map));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> cancelReservation(int id) async {
    try {
      await _dio.post('/reservations/$id/cancel');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final reservationRepositoryProvider =
    Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(dioProvider));
});
