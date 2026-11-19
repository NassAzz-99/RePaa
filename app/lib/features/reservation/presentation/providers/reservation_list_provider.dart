import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/reservation_model.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../../../core/network/api_exception.dart';

class ReservationListState {
  final bool isLoading;
  final List<ReservationModel> reservations;
  final String? errorMessage;

  const ReservationListState({
    this.isLoading = false,
    this.reservations = const [],
    this.errorMessage,
  });

  ReservationListState copyWith({
    bool? isLoading,
    List<ReservationModel>? reservations,
    String? errorMessage,
  }) {
    return ReservationListState(
      isLoading: isLoading ?? this.isLoading,
      reservations: reservations ?? this.reservations,
      errorMessage: errorMessage,
    );
  }
}

class ReservationListNotifier
    extends StateNotifier<ReservationListState> {
  final ReservationRepository _repo;

  ReservationListNotifier(this._repo)
      : super(const ReservationListState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getMyReservations();
      state = state.copyWith(isLoading: false, reservations: list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Gagal memuat riwayat: $e');
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _repo.cancelReservation(id);
      await load(); // refresh
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Gagal membatalkan reservasi: $e');
    }
  }
}

final reservationListProvider =
    StateNotifierProvider<ReservationListNotifier, ReservationListState>(
        (ref) {
  return ReservationListNotifier(ref.watch(reservationRepositoryProvider));
});
