import 'package:dio/dio.dart';

/// Exception terpusat untuk semua error API.
/// Memudahkan UI menampilkan pesan dalam bahasa Indonesia.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? errors; // validasi 422

  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Buat ApiException dari DioException.
  factory ApiException.fromDioError(DioException e) {
    final response = e.response;

    if (response == null) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const ApiException(
          message: 'Koneksi timeout. Periksa jaringan Anda.',
        );
      }
      return const ApiException(
        message: 'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
      );
    }

    final data = response.data;
    final message = (data is Map && data['message'] != null)
        ? data['message'] as String
        : 'Terjadi kesalahan. Coba lagi.';

    // Ambil field errors untuk status 422
    Map<String, List<String>>? errors;
    if (response.statusCode == 422 && data is Map && data['errors'] != null) {
      final raw = data['errors'] as Map<String, dynamic>;
      errors = raw.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e.toString()).toList(),
        ),
      );
    }

    return ApiException(
      message: message,
      statusCode: response.statusCode,
      errors: errors,
    );
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
