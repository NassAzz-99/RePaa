import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/report_model.dart';
import '../../data/repositories/admin_report_repository.dart';

class AdminReportState {
  final bool isLoading;
  final ReportModel? data;
  final String? errorMessage;
  final String period; // 'daily' | 'weekly'
  final String startDate;

  const AdminReportState({
    this.isLoading = false,
    this.data,
    this.errorMessage,
    this.period = 'daily',
    this.startDate = '',
  });

  AdminReportState copyWith({
    bool? isLoading,
    ReportModel? data,
    String? errorMessage,
    String? period,
    String? startDate,
  }) =>
      AdminReportState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        errorMessage: errorMessage,
        period: period ?? this.period,
        startDate: startDate ?? this.startDate,
      );
}

class AdminReportNotifier extends StateNotifier<AdminReportState> {
  final AdminReportRepository _repo;

  AdminReportNotifier(this._repo) : super(AdminReportState(startDate: _today())) {
    load();
  }

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final data = await _repo.getReport(
        period: state.period,
        startDate: state.startDate,
      );
      state = state.copyWith(isLoading: false, data: data);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setPeriod(String period) {
    state = state.copyWith(period: period);
    load();
  }

  void setStartDate(String date) {
    state = state.copyWith(startDate: date);
    load();
  }
}

final adminReportProvider =
    StateNotifierProvider<AdminReportNotifier, AdminReportState>((ref) {
  return AdminReportNotifier(ref.watch(adminReportRepositoryProvider));
});
