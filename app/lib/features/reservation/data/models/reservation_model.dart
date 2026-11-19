/// Model Reservasi sesuai blueprint response POST /reservations, GET /reservations/:id
class ReservationModel {
  final int id;
  final String status;
  final String reservationDate;
  final String workUnit;
  final String purpose;
  final String? adminNote;
  final ReservationVehicle vehicle;
  final ReservationBatch batch;
  final ReservationUser user;
  final String createdAt;

  const ReservationModel({
    required this.id,
    required this.status,
    required this.reservationDate,
    required this.workUnit,
    required this.purpose,
    this.adminNote,
    required this.vehicle,
    required this.batch,
    required this.user,
    required this.createdAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final vehicleMap = json['vehicle'] is Map
        ? Map<String, dynamic>.from(json['vehicle'] as Map)
        : <String, dynamic>{};
    final batchMap = json['batch'] is Map
        ? Map<String, dynamic>.from(json['batch'] as Map)
        : <String, dynamic>{};
    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : <String, dynamic>{};

    return ReservationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'pending',
      reservationDate: json['reservation_date']?.toString() ?? '',
      workUnit: json['work_unit']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      adminNote: json['admin_note']?.toString(),
      vehicle: ReservationVehicle.fromJson(vehicleMap),
      batch: ReservationBatch.fromJson(batchMap),
      user: ReservationUser.fromJson(userMap),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  /// Label status dalam bahasa Indonesia sesuai blueprint.
  String get statusLabel {
    const labels = {
      'pending': 'Menunggu Persetujuan',
      'approved': 'Disetujui',
      'rejected': 'Ditolak',
      'cancelled': 'Dibatalkan',
      'completed': 'Selesai',
    };
    return labels[status] ?? status;
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
}

class ReservationVehicle {
  final int id;
  final String name;
  final String type;
  final String? photoUrl;

  const ReservationVehicle({
    required this.id,
    required this.name,
    required this.type,
    this.photoUrl,
  });

  factory ReservationVehicle.fromJson(Map<String, dynamic> json) {
    return ReservationVehicle(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '-',
      type: json['type']?.toString() ?? '-',
      photoUrl: json['photo_url']?.toString(),
    );
  }
}

class ReservationBatch {
  final int id;
  final String name;
  final String startTime;
  final String endTime;

  const ReservationBatch({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
  });

  factory ReservationBatch.fromJson(Map<String, dynamic> json) {
    return ReservationBatch(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '-',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }

  String get displayTime => '$startTime – $endTime';
}

class ReservationUser {
  final int id;
  final String name;
  final String? email;

  const ReservationUser({
    required this.id,
    required this.name,
    this.email,
  });

  factory ReservationUser.fromJson(Map<String, dynamic> json) {
    return ReservationUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '-',
      email: json['email']?.toString(),
    );
  }
}
