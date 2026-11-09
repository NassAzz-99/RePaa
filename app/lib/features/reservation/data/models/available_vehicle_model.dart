/// Model untuk dropdown kendaraan tersedia
/// Blueprint: GET /vehicles/available?date=&batch_id=
class AvailableVehicleModel {
  final int id;
  final String name;
  final String type;
  final String? photoUrl;

  const AvailableVehicleModel({
    required this.id,
    required this.name,
    required this.type,
    this.photoUrl,
  });

  factory AvailableVehicleModel.fromJson(Map<String, dynamic> json) {
    return AvailableVehicleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      photoUrl: json['photo_url'] as String?,
    );
  }
}
