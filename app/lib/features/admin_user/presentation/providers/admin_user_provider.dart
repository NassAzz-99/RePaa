import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_user_repository.dart';

class AdminUserState {
  final bool isLoading;
  final List<AdminUserModel> users;
  final String? errorMessage;

  const AdminUserState({
    this.isLoading = false,
    this.users = const [],
    this.errorMessage,
  });

  AdminUserState copyWith({
    bool? isLoading,
    List<AdminUserModel>? users,
    String? errorMessage,
  }) =>
      AdminUserState(
        isLoading: isLoading ?? this.isLoading,
        users: users ?? this.users,
        errorMessage: errorMessage,
      );
}

class AdminUserNotifier extends StateNotifier<AdminUserState> {
  final AdminUserRepository _repo;
  AdminUserNotifier(this._repo) : super(const AdminUserState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getAll();
      state = state.copyWith(isLoading: false, users: list);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> toggleRole(int id, String currentRole) async {
    final newRole = currentRole == 'admin' ? 'user' : 'admin';
    try {
      final updated = await _repo.setRole(id, newRole);
      state = state.copyWith(
        users: state.users.map((u) => u.id == id ? updated : u).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  Future<void> toggleActive(int id, bool currentActive) async {
    try {
      final updated = await _repo.setActive(id, !currentActive);
      state = state.copyWith(
        users: state.users.map((u) => u.id == id ? updated : u).toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}

final adminUserProvider =
    StateNotifierProvider<AdminUserNotifier, AdminUserState>((ref) {
  return AdminUserNotifier(ref.watch(adminUserRepositoryProvider));
});

