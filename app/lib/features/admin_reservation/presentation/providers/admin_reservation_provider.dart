import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reservation/data/models/reservation_model.dart';
import '../../data/repositories/admin_reservation_repository.dart';

class AdminReservationFilter {
  final String? status;
  final String? date;
  final String? workUnit;

  const AdminReservationFilter({this.status, this.date, this.workUnit});

  bool get isActive =>
      (status != null && status != 'all') ||
      (date != null && date!.isNotEmpty) ||
      (workUnit != null && workUnit!.isNotEmpty);

  AdminReservationFilter copyWith({
    String? status,
    String? date,
    String? workUnit,
  }) =>
      AdminReservationFilter(
        status: status ?? this.status,
        date: date ?? this.date,
        workUnit: workUnit ?? this.workUnit,
      );
}

class AdminReservationState {
  final bool isLoading;
  final List<ReservationModel> reservations;
  final String? errorMessage;
  final AdminReservationFilter filter;

  const AdminReservationState({
    this.isLoading = false,
    this.reservations = const [],
    this.errorMessage,
    this.filter = const AdminReservationFilter(),
  });

  AdminReservationState copyWith({
    bool? isLoading,
    List<ReservationModel>? reservations,
    String? errorMessage,
    AdminReservationFilter? filter,
  }) =>
      AdminReservationState(
        isLoading: isLoading ?? this.isLoading,
        reservations: reservations ?? this.reservations,
        errorMessage: errorMessage,
        filter: filter ?? this.filter,
      );
}

class AdminReservationNotifier extends StateNotifier<AdminReservationState> {
  final AdminReservationRepository _repo;
  AdminReservationNotifier(this._repo) : super(const AdminReservationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAll(
        status: state.filter.status,
        date: state.filter.date,
        workUnit: state.filter.workUnit,
      );
      state = state.copyWith(isLoading: false, reservations: list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  void setFilter(AdminReservationFilter filter) {
    state = state.copyWith(filter: filter);
    load();
  }

  void clearFilter() {
    state = state.copyWith(filter: const AdminReservationFilter());
    load();
  }

  Future<void> approve(int id) async {
    try {
      await _repo.approve(id);
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> reject(int id, String? note) async {
    try {
      await _repo.reject(id, note);
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> complete(int id) async {
    try {
      await _repo.complete(id);
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

final adminReservationProvider =
    StateNotifierProvider<AdminReservationNotifier, AdminReservationState>(
        (ref) {
  return AdminReservationNotifier(
      ref.watch(adminReservationRepositoryProvider));
});

