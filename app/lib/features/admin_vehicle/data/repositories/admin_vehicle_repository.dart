import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/vehicle_model.dart';

class AdminVehicleRepository {
  final Dio _dio;
  AdminVehicleRepository(this._dio);

  Future<List<VehicleModel>> getAll() async {
    try {
      final res = await _dio.get('/admin/vehicles');
      final list = res.data['data'] as List;
      return list
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VehicleModel> create({
    required String name,
    required String type,
    required String status,
    String? photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'type': type,
        'status': status,
        if (photoPath != null)
          'photo': await MultipartFile.fromFile(photoPath),
      });
      final res = await _dio.post('/admin/vehicles', data: formData);
      return VehicleModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VehicleModel> update({
    required int id,
    required String name,
    required String type,
    required String status,
    String? photoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'type': type,
        'status': status,
        if (photoPath != null)
          'photo': await MultipartFile.fromFile(photoPath),
      });
      final res = await _dio.put('/admin/vehicles/$id', data: formData);
      return VehicleModel.fromJson(
          res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/admin/vehicles/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final adminVehicleRepositoryProvider =
    Provider<AdminVehicleRepository>((ref) {
  return AdminVehicleRepository(ref.watch(dioProvider));
});

