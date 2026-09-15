import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';

class MemberSettlementSummaryModel extends MemberSettlementSummary {
  const MemberSettlementSummaryModel({
    required super.userId,
    required super.username,
    required super.fullName,
    required super.totalMeals,
    required super.weightedMeals,
    required super.foodCharge,
    required super.fixedShare,
    required super.otherShare,
    required super.totalPaid,
    required super.totalOwed,
    required super.carryForwardIn,
    required super.netBalance,
  });

  factory MemberSettlementSummaryModel.fromJson(Map<String, dynamic> json) {
    return MemberSettlementSummaryModel(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      totalMeals: (json['total_meals'] as num?)?.toDouble() ?? 0.0,
      weightedMeals: (json['weighted_meals'] as num?)?.toDouble() ?? 0.0,
      foodCharge: (json['food_charge'] as num?)?.toDouble() ?? 0.0,
      fixedShare: (json['fixed_share'] as num?)?.toDouble() ?? 0.0,
      otherShare: (json['other_share'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalOwed: (json['total_owed'] as num?)?.toDouble() ?? 0.0,
      carryForwardIn: (json['carry_forward_in'] as num?)?.toDouble() ?? 0.0,
      netBalance: (json['net_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SettlementModel extends Settlement {
  const SettlementModel({
    required super.houseId,
    required super.cycleId,
    required super.totalFoodCost,
    required super.totalFixedCost,
    required super.totalOtherCost,
    required super.totalMealCount,
    required super.mealRate,
    required super.memberSummaries,
    super.computedAt,
    super.calculationEndDate,
  });

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    final summariesList = (json['member_summaries'] as List? ?? [])
        .map((m) => MemberSettlementSummaryModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return SettlementModel(
      houseId: json['house_id'] as String? ?? '',
      cycleId: json['cycle_id'] as String? ?? '',
      totalFoodCost: (json['total_food_cost'] as num?)?.toDouble() ?? 0.0,
      totalFixedCost: (json['total_fixed_cost'] as num?)?.toDouble() ?? 0.0,
      totalOtherCost: (json['total_other_cost'] as num?)?.toDouble() ?? 0.0,
      totalMealCount: (json['total_meal_count'] as num?)?.toDouble() ?? 0.0,
      mealRate: (json['meal_rate'] as num?)?.toDouble() ?? 0.0,
      memberSummaries: summariesList,
      computedAt: json['computed_at'] != null
          ? DateTime.tryParse(json['computed_at'] as String)
          : null,
      calculationEndDate: json['calculation_end_date'] != null
          ? DateTime.tryParse(json['calculation_end_date'] as String)
          : null,
    );
  }
}
