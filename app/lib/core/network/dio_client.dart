import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../services/storage_service.dart';

/// Membuat instance Dio yang sudah dikonfigurasi dengan:
/// - BaseURL, timeout
/// - Interceptor yang menambahkan header `Authorization: Bearer token` otomatis
/// - Interceptor log untuk development
Dio createDioClient(StorageService storageService) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Auth interceptor: sisipkan token ke setiap request
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ),
  );

  // Log interceptor (nonaktifkan di production)
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => debugPrint(o.toString()),
    ),
  );

  return dio;
}

/// Provider Dio global – seluruh app memakai instance ini.
final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return createDioClient(storage);
});
