/// Model Batch sesuai blueprint response GET /batches
class BatchModel {
  final int id;
  final String name;
  final String startTime;
  final String endTime;
  final bool isActive;

  const BatchModel({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isActive,
  });

  factory BatchModel.fromJson(Map<String, dynamic> json) {
    return BatchModel(
      id: json['id'] as int,
      name: json['name'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      isActive: json['is_active'] as bool,
    );
  }

  String get displayTime => '$startTime – $endTime';
  String get displayLabel => '$name  ($displayTime)';
}
