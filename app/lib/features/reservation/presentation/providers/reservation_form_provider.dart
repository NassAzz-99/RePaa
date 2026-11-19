import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/available_vehicle_model.dart';
import '../../data/models/batch_model.dart';
import '../../data/models/reservation_model.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../../../core/network/api_exception.dart';

// ── State ─────────────────────────────────────────────────

enum FormStatus { idle, loading, success, error }

class ReservationFormState {
  final FormStatus status;
  final List<BatchModel> batches;
  final List<AvailableVehicleModel> availableVehicles;
  final List<String> workUnitSuggestions;
  final ReservationModel? createdReservation;
  final String? errorMessage;
  final Map<String, List<String>>? fieldErrors;

  // Form fields
  final String? selectedDate;
  final BatchModel? selectedBatch;
  final AvailableVehicleModel? selectedVehicle;

  const ReservationFormState({
    this.status = FormStatus.idle,
    this.batches = const [],
    this.availableVehicles = const [],
    this.workUnitSuggestions = const [],
    this.createdReservation,
    this.errorMessage,
    this.fieldErrors,
    this.selectedDate,
    this.selectedBatch,
    this.selectedVehicle,
  });

  bool get isLoadingBatches => status == FormStatus.loading && batches.isEmpty;
  bool get isLoadingVehicles =>
      status == FormStatus.loading && batches.isNotEmpty;
  bool get isSubmitting => status == FormStatus.loading;
  bool get isSuccess => status == FormStatus.success;

  ReservationFormState copyWith({
    FormStatus? status,
    List<BatchModel>? batches,
    List<AvailableVehicleModel>? availableVehicles,
    List<String>? workUnitSuggestions,
    ReservationModel? createdReservation,
    String? errorMessage,
    Map<String, List<String>>? fieldErrors,
    String? selectedDate,
    BatchModel? selectedBatch,
    AvailableVehicleModel? selectedVehicle,
  }) {
    return ReservationFormState(
      status: status ?? this.status,
      batches: batches ?? this.batches,
      availableVehicles: availableVehicles ?? this.availableVehicles,
      workUnitSuggestions: workUnitSuggestions ?? this.workUnitSuggestions,
      createdReservation: createdReservation ?? this.createdReservation,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedBatch: selectedBatch ?? this.selectedBatch,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────

class ReservationFormNotifier extends StateNotifier<ReservationFormState> {
  final ReservationRepository _repo;
  int? _preSelectedVehicleId;

  ReservationFormNotifier(this._repo) : super(const ReservationFormState()) {
    _loadBatches();
  }

  void setPreSelectedVehicleId(int? id) {
    _preSelectedVehicleId = id;
    if (id != null) {
      preSelectVehicle(id);
    }
  }

  Future<void> _loadBatches() async {
    state = state.copyWith(status: FormStatus.loading);
    try {
      final batches = await _repo.getBatches();
      state = state.copyWith(status: FormStatus.idle, batches: batches);
    } on ApiException catch (e) {
      state = state.copyWith(status: FormStatus.error, errorMessage: e.message);
    }
  }

  void setDate(String date) {
    state = state.copyWith(
      selectedDate: date,
      selectedBatch: null,
      selectedVehicle: null,
      availableVehicles: [],
    );
  }

  Future<void> setBatch(BatchModel batch) async {
    state = state.copyWith(
      selectedBatch: batch,
      selectedVehicle: null,
      availableVehicles: [],
    );
    if (state.selectedDate != null) {
      await _loadAvailableVehicles();
    }
  }

  void setVehicle(AvailableVehicleModel vehicle) {
    state = state.copyWith(selectedVehicle: vehicle);
  }

  /// Dipanggil saat kendaraan sudah dipilih dari dashboard (vehicleId dikirim via route).
  void preSelectVehicle(int vehicleId) {
    final match = state.availableVehicles
        .where((v) => v.id == vehicleId)
        .firstOrNull;
    if (match != null) {
      state = state.copyWith(selectedVehicle: match);
    }
  }

  Future<void> _loadAvailableVehicles() async {
    state = state.copyWith(status: FormStatus.loading);
    try {
      final vehicles = await _repo.getAvailableVehicles(
        date: state.selectedDate!,
        batchId: state.selectedBatch!.id,
      );
      AvailableVehicleModel? selected;
      if (_preSelectedVehicleId != null) {
        selected = vehicles
            .where((v) => v.id == _preSelectedVehicleId)
            .firstOrNull;
      }
      state = state.copyWith(
        status: FormStatus.idle,
        availableVehicles: vehicles,
        selectedVehicle: selected,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: FormStatus.error,
        errorMessage: e.message,
      );
    }
  }

  Future<void> searchWorkUnits(String query) async {
    if (query.length < 2) {
      state = state.copyWith(workUnitSuggestions: []);
      return;
    }
    try {
      final suggestions = await _repo.getWorkUnitSuggestions(query);
      state = state.copyWith(workUnitSuggestions: suggestions);
    } catch (_) {
      // Abaikan error autocomplete
    }
  }

  Future<void> submit({
    required String workUnit,
    required String purpose,
  }) async {
    if (state.selectedDate == null ||
        state.selectedBatch == null ||
        state.selectedVehicle == null) {
      state = state.copyWith(
        status: FormStatus.error,
        errorMessage: 'Lengkapi semua field terlebih dahulu.',
      );
      return;
    }

    state = state.copyWith(
      status: FormStatus.loading,
      errorMessage: null,
      fieldErrors: null,
    );
    try {
      final result = await _repo.createReservation(
        vehicleId: state.selectedVehicle!.id,
        batchId: state.selectedBatch!.id,
        reservationDate: state.selectedDate!,
        workUnit: workUnit,
        purpose: purpose,
      );
      state = state.copyWith(
        status: FormStatus.success,
        createdReservation: result.data,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: FormStatus.error,
        errorMessage: e.message,
        fieldErrors: e.errors,
      );
    }
  }

  void reset() {
    state = ReservationFormState(batches: state.batches);
  }
}

final reservationFormProvider =
    StateNotifierProvider.autoDispose<ReservationFormNotifier,
        ReservationFormState>((ref) {
  return ReservationFormNotifier(ref.watch(reservationRepositoryProvider));
});
