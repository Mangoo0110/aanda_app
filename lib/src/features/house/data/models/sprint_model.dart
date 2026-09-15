import 'package:aanda/src/features/house/domain/entities/sprint.dart';

class SprintModel extends Sprint {
  const SprintModel({
    required super.id,
    required super.houseId,
    required super.label,
    required super.startDate,
    required super.endDate,
    required super.status,
    super.breakfastWeight = 1.0,
    super.lunchWeight = 1.0,
    super.dinnerWeight = 1.0,
    super.closedAt,
    super.createdBy,
  });

  factory SprintModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'open';
    return SprintModel(
      id: json['id'] as String,
      houseId: json['house_id'] as String,
      label: (json['label'] as String?)?.isNotEmpty == true
          ? json['label'] as String
          : 'Sprint',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      status: statusStr == 'closed' ? SprintStatus.closed : SprintStatus.open,
      breakfastWeight: (json['breakfast_weight'] as num?)?.toDouble() ?? 1.0,
      lunchWeight: (json['lunch_weight'] as num?)?.toDouble() ?? 1.0,
      dinnerWeight: (json['dinner_weight'] as num?)?.toDouble() ?? 1.0,
      closedAt: json['closed_at'] != null
          ? DateTime.tryParse(json['closed_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'house_id': houseId,
      'label': label,
      'start_date': startDate.toIso8601String().substring(0, 10),
      'end_date': endDate.toIso8601String().substring(0, 10),
      'status': status == SprintStatus.closed ? 'closed' : 'open',
      'cycle_type': 'dynamic',
      'breakfast_weight': breakfastWeight,
      'lunch_weight': lunchWeight,
      'dinner_weight': dinnerWeight,
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      if (createdBy != null) 'created_by': createdBy,
    };
  }
}
