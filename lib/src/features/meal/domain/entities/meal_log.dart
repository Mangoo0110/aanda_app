class MealLog {
  const MealLog({
    required this.id,
    required this.houseId,
    required this.cycleId,
    required this.userId,
    required this.logDate,
    this.breakfast = 0.0,
    this.lunch = 0.0,
    this.dinner = 0.0,
    this.memberName,
    this.updatedAt,
  });

  final String id;
  final String houseId;
  final String cycleId;
  final String userId;
  final DateTime logDate;
  final double breakfast;
  final double lunch;
  final double dinner;
  final String? memberName;
  final DateTime? updatedAt;

  double get totalMeals => breakfast + lunch + dinner;

  MealLog copyWith({
    String? id,
    String? houseId,
    String? cycleId,
    String? userId,
    DateTime? logDate,
    double? breakfast,
    double? lunch,
    double? dinner,
    String? memberName,
    DateTime? updatedAt,
  }) {
    return MealLog(
      id: id ?? this.id,
      houseId: houseId ?? this.houseId,
      cycleId: cycleId ?? this.cycleId,
      userId: userId ?? this.userId,
      logDate: logDate ?? this.logDate,
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      memberName: memberName ?? this.memberName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
