import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

class MealLogModel extends MealLog {
  const MealLogModel({
    required super.id,
    required super.houseId,
    required super.cycleId,
    required super.userId,
    required super.logDate,
    super.breakfast = 0.0,
    super.lunch = 0.0,
    super.dinner = 0.0,
    super.memberName,
    super.updatedAt,
  });

  factory MealLogModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    final memberName = profile?['full_name'] ?? profile?['username'];

    return MealLogModel(
      id: json['id'] as String,
      houseId: (json['expense_account_id'] ?? json['house_id'] ?? '') as String,
      cycleId: json['cycle_id'] as String,
      userId: json['user_id'] as String,
      logDate: DateTime.parse(json['log_date'] as String),
      breakfast: (json['breakfast'] as num?)?.toDouble() ?? 0.0,
      lunch: (json['lunch'] as num?)?.toDouble() ?? 0.0,
      dinner: (json['dinner'] as num?)?.toDouble() ?? 0.0,
      memberName: memberName as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_account_id': houseId,
      'cycle_id': cycleId,
      'user_id': userId,
      'log_date': logDate.toIso8601String().substring(0, 10),
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}
