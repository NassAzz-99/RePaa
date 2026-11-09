/// Validator form Flutter (sisi client).
/// Validasi sisi server tetap dipegang oleh Node.js backend.
class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Field ini']) {
    if (value == null || value.trim().isEmpty) {
      return '$field wajib diisi.';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi.';
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value.trim())) return 'Format email tidak valid.';
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'Field ini']) {
    if (value == null || value.isEmpty) return '$field wajib diisi.';
    if (value.length < min) return '$field minimal $min karakter.';
    return null;
  }

  static String? password(String? value) {
    return minLength(value, 8, 'Password');
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Konfirmasi password tidak cocok.';
    return null;
  }
}
