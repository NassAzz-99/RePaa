/// Konstanta URL API sesuai blueprint.
/// Emulator Android: http://10.0.2.2:3000/api
/// Perangkat fisik: ganti dengan IP LAN laptop, misal http://192.168.x.x:3000/api
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
