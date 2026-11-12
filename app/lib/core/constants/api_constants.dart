import 'package:flutter/foundation.dart';

/// Konstanta URL API sesuai blueprint.
/// - Web / Windows Desktop: http://localhost:3000/api
/// - Emulator Android: http://10.0.2.2:3000/api
/// - Perangkat fisik: ganti dengan IP LAN laptop (misal http://192.168.x.x:3000/api)
class ApiConstants {
  ApiConstants._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/api';
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return 'http://localhost:3000/api';
      default:
        return 'http://10.0.2.2:3000/api';
    }
  }

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
}
