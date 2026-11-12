class VehicleModel {
  final int id;
  final String name;
  final String type;
  final String status; // 'available' | 'maintenance'
  final String? photoUrl;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.photoUrl,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> j) {
    return VehicleModel(
      id: j['id'] as int,
      name: j['name'] as String,
      type: j['type'] as String,
      status: j['status'] as String? ?? 'available',
      photoUrl: j['photo_url'] as String?,
    );
  }

  String get statusLabel =>
      status == 'available' ? 'Tersedia' : 'Perawatan';
}

