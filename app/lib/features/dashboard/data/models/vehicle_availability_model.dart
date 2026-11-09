/// Model untuk response GET /vehicles/availability
/// Blueprint: { date, vehicles: [ { id, name, type, status, photo_url, slots: [] } ] }

class VehicleAvailabilityModel {
  final String date;
  final List<VehicleSlotModel> vehicles;

  const VehicleAvailabilityModel({
    required this.date,
    required this.vehicles,
  });

  factory VehicleAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return VehicleAvailabilityModel(
      date: json['date'] as String,
      vehicles: (json['vehicles'] as List)
          .map((v) => VehicleSlotModel.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class VehicleSlotModel {
  final int id;
  final String name;
  final String type;
  final String status; // 'available' | 'maintenance' | 'inactive'
  final String? photoUrl;
  final List<BatchSlotModel> slots;

  const VehicleSlotModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    this.photoUrl,
    required this.slots,
  });

  bool get isAvailable => status == 'available';

  factory VehicleSlotModel.fromJson(Map<String, dynamic> json) {
    return VehicleSlotModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      photoUrl: json['photo_url'] as String?,
      slots: (json['slots'] as List)
          .map((s) => BatchSlotModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BatchSlotModel {
  final int batchId;
  final String batchName;
  final String startTime;
  final String endTime;
  final String status; // 'empty' | 'pending' | 'booked'

  const BatchSlotModel({
    required this.batchId,
    required this.batchName,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory BatchSlotModel.fromJson(Map<String, dynamic> json) {
    return BatchSlotModel(
      batchId: json['batch_id'] as int,
      batchName: json['batch_name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      status: json['status'] as String,
    );
  }
}
