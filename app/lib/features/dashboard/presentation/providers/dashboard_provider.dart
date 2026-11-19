import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/vehicle_availability_model.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../../../core/network/api_exception.dart';

// ── State ─────────────────────────────────────────────────

class DashboardState {
  final bool isLoading;
  final VehicleAvailabilityModel? data;
  final String? errorMessage;
  final String selectedDate; // YYYY-MM-DD

  const DashboardState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
    required this.selectedDate,
  });

  DashboardState copyWith({
    bool? isLoading,
    VehicleAvailabilityModel? data,
    String? errorMessage,
    String? selectedDate,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      errorMessage: errorMessage,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repo;

  DashboardNotifier(this._repo)
      : super(DashboardState(selectedDate: _todayString())) {
    load();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> load({String? date}) async {
    final targetDate = date ?? state.selectedDate;
    state = state.copyWith(isLoading: true, errorMessage: null, selectedDate: targetDate);
    try {
      final data = await _repo.getAvailability(date: targetDate);
      state = state.copyWith(isLoading: false, data: data, errorMessage: null);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat ketersediaan: $e');
    }
  }

  Future<void> refresh() => load();
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.watch(dashboardRepositoryProvider));
});
