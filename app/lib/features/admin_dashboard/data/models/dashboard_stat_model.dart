class PendingReservationItem {
  final int id;
  final String userName;
  final String userEmail;
  final String workUnit;
  final String vehicleName;
  final String reservationDate;
  final String batchName;
  final String batchStartTime;
  final String batchEndTime;

  const PendingReservationItem({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.workUnit,
    required this.vehicleName,
    required this.reservationDate,
    required this.batchName,
    required this.batchStartTime,
    required this.batchEndTime,
  });

  factory PendingReservationItem.fromJson(Map<String, dynamic> j) {
    final batch = j['batch'] as Map<String, dynamic>? ?? {};
    final vehicle = j['vehicle'] as Map<String, dynamic>? ?? {};
    final user = j['user'] as Map<String, dynamic>? ?? {};
    return PendingReservationItem(
      id: j['id'] as int,
      userName: user['name'] as String? ?? '',
      userEmail: user['email'] as String? ?? '',
      workUnit: j['work_unit'] as String? ?? '',
      vehicleName: vehicle['name'] as String? ?? '',
      reservationDate: j['reservation_date'] as String? ?? '',
      batchName: batch['name'] as String? ?? '',
      batchStartTime: batch['start_time'] as String? ?? '',
      batchEndTime: batch['end_time'] as String? ?? '',
    );
  }
}

class DashboardStatModel {
  final int pending;
  final int approved;
  final int availableVehicles;
  final int totalUsers;
  final Map<String, int> statusDistribution;
  final List<PendingReservationItem> pendingList;

  const DashboardStatModel({
    required this.pending,
    required this.approved,
    required this.availableVehicles,
    required this.totalUsers,
    required this.statusDistribution,
    required this.pendingList,
  });

  factory DashboardStatModel.fromJson(Map<String, dynamic> j) {
    final dist = (j['status_distribution'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final pendingList = (j['pending_reservations'] as List? ?? [])
        .map((e) => PendingReservationItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return DashboardStatModel(
      pending: (j['pending'] as num? ?? 0).toInt(),
      approved: (j['approved'] as num? ?? 0).toInt(),
      availableVehicles: (j['available_vehicles'] as num? ?? 0).toInt(),
      totalUsers: (j['total_users'] as num? ?? 0).toInt(),
      statusDistribution: dist,
      pendingList: pendingList,
    );
  }
}

