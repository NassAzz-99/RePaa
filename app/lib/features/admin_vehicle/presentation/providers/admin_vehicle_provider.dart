import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/vehicle_model.dart';
import '../../data/repositories/admin_vehicle_repository.dart';

class AdminVehicleState {
  final bool isLoading;
  final List<VehicleModel> vehicles;
  final String? errorMessage;

  const AdminVehicleState({
    this.isLoading = false,
    this.vehicles = const [],
    this.errorMessage,
  });

  AdminVehicleState copyWith({
    bool? isLoading,
    List<VehicleModel>? vehicles,
    String? errorMessage,
  }) =>
      AdminVehicleState(
        isLoading: isLoading ?? this.isLoading,
        vehicles: vehicles ?? this.vehicles,
        errorMessage: errorMessage,
      );
}

class AdminVehicleNotifier extends StateNotifier<AdminVehicleState> {
  final AdminVehicleRepository _repo;
  AdminVehicleNotifier(this._repo) : super(const AdminVehicleState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAll();
      state = state.copyWith(isLoading: false, vehicles: list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repo.delete(id);
      state = state.copyWith(
          vehicles: state.vehicles.where((v) => v.id != id).toList());
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<bool> save({
    int? id,
    required String name,
    required String type,
    required String status,
    String? photoPath,
  }) async {
    try {
      if (id == null) {
        final v = await _repo.create(
            name: name, type: type, status: status, photoPath: photoPath);
        state = state.copyWith(vehicles: [...state.vehicles, v]);
      } else {
        final v = await _repo.update(
            id: id,
            name: name,
            type: type,
            status: status,
            photoPath: photoPath);
        state = state.copyWith(
          vehicles: state.vehicles.map((x) => x.id == id ? v : x).toList(),
        );
      }
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return false;
    }
  }
}

final adminVehicleProvider =
    StateNotifierProvider<AdminVehicleNotifier, AdminVehicleState>((ref) {
  return AdminVehicleNotifier(ref.watch(adminVehicleRepositoryProvider));
});

