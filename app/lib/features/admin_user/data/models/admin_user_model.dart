class AdminUserModel {
  final int id;
  final String name;
  final String email;
  final String role; // 'user' | 'admin'
  final bool isActive;
  final int totalReservations;
  final String createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.totalReservations,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> j) {
    return AdminUserModel(
      id: j['id'] as int,
      name: j['name'] as String,
      email: j['email'] as String,
      role: j['role'] as String? ?? 'user',
      isActive: j['is_active'] as bool? ?? true,
      totalReservations:
          (j['total_reservations'] as num? ?? 0).toInt(),
      createdAt: j['created_at'] as String? ?? '',
    );
  }

  String get roleLabel => role == 'admin' ? 'Admin' : 'Pengguna';
}

