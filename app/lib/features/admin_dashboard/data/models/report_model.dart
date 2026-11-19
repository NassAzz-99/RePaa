class DailyTrendItem {
  final String date;
  final int count;
  const DailyTrendItem({required this.date, required this.count});

  factory DailyTrendItem.fromJson(Map<String, dynamic> j) {
    return DailyTrendItem(
      date: j['date'] as String,
      count: (j['count'] as num).toInt(),
    );
  }
}

class ReportModel {
  final Map<String, int> statusSummary;
  final List<DailyTrendItem> trend;
  final Map<String, int> vehicleStatus;

  const ReportModel({
    required this.statusSummary,
    required this.trend,
    required this.vehicleStatus,
  });

  factory ReportModel.fromJson(Map<String, dynamic> j) {
    final summary = (j['status_summary'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    final trend = (j['trend'] as List? ?? [])
        .map((e) => DailyTrendItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final vs = (j['vehicle_status'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, (v as num).toInt()));
    return ReportModel(
        statusSummary: summary, trend: trend, vehicleStatus: vs);
  }
}
