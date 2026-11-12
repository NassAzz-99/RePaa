import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/dashboard_stat_model.dart';
import '../../data/repositories/admin_dashboard_repository.dart';

class AdminDashboardState {
  final bool isLoading;
  final DashboardStatModel? data;
  final String? errorMessage;

  const AdminDashboardState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    DashboardStatModel? data,
    String? errorMessage,
  }) =>
      AdminDashboardState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        errorMessage: errorMessage,
      );
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  final AdminDashboardRepository _repo;
  AdminDashboardNotifier(this._repo) : super(const AdminDashboardState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repo.getStats();
      state = state.copyWith(isLoading: false, data: data);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> approve(int id) async {
    try {
      await _repo.approveReservation(id);
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> reject(int id, String? note) async {
    try {
      await _repo.rejectReservation(id, note);
      await load();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

final adminDashboardProvider =
    StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier(ref.watch(adminDashboardRepositoryProvider));
});

