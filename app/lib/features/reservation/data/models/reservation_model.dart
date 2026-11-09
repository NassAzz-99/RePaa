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
    return ReservationModel(
      id: json['id'] as int,
      status: json['status'] as String,
      reservationDate: json['reservation_date'] as String,
      workUnit: json['work_unit'] as String,
      purpose: json['purpose'] as String,
      adminNote: json['admin_note'] as String?,
      vehicle: ReservationVehicle.fromJson(
          json['vehicle'] as Map<String, dynamic>),
      batch:
          ReservationBatch.fromJson(json['batch'] as Map<String, dynamic>),
      user: ReservationUser.fromJson(json['user'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String,
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
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      photoUrl: json['photo_url'] as String?,
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
      id: json['id'] as int,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
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
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
    );
  }
}
