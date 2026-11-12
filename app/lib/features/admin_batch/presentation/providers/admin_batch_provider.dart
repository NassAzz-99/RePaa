import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../reservation/data/models/batch_model.dart';
import '../../data/repositories/admin_batch_repository.dart';

class AdminBatchState {
  final bool isLoading;
  final List<BatchModel> batches;
  final String? errorMessage;
  final int? savingId;

  const AdminBatchState({
    this.isLoading = false,
    this.batches = const [],
    this.errorMessage,
    this.savingId,
  });

  AdminBatchState copyWith({
    bool? isLoading,
    List<BatchModel>? batches,
    String? errorMessage,
    int? savingId,
  }) =>
      AdminBatchState(
        isLoading: isLoading ?? this.isLoading,
        batches: batches ?? this.batches,
        errorMessage: errorMessage,
        savingId: savingId,
      );
}

class AdminBatchNotifier extends StateNotifier<AdminBatchState> {
  final AdminBatchRepository _repo;
  AdminBatchNotifier(this._repo) : super(const AdminBatchState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAll();
      state = state.copyWith(isLoading: false, batches: list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<bool> updateBatch({
    required int id,
    required String name,
    required String startTime,
    required String endTime,
    required bool isActive,
  }) async {
    state = state.copyWith(savingId: id);
    try {
      final updated = await _repo.update(
        id: id,
        name: name,
        startTime: startTime,
        endTime: endTime,
        isActive: isActive,
      );
      state = state.copyWith(
        batches: state.batches.map((b) => b.id == id ? updated : b).toList(),
        savingId: null,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, savingId: null);
      return false;
    }
  }
}

final adminBatchProvider =
    StateNotifierProvider<AdminBatchNotifier, AdminBatchState>((ref) {
  return AdminBatchNotifier(ref.watch(adminBatchRepositoryProvider));
});

