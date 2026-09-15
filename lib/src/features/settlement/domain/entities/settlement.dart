class MemberSettlementSummary {
  const MemberSettlementSummary({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.totalMeals,
    required this.weightedMeals,
    required this.foodCharge,
    required this.fixedShare,
    required this.otherShare,
    required this.totalPaid,
    required this.totalOwed,
    required this.carryForwardIn,
    required this.netBalance,
  });

  final String userId;
  final String username;
  final String fullName;
  final double totalMeals;
  final double weightedMeals;
  final double foodCharge;
  final double fixedShare;
  final double otherShare;
  final double totalPaid;
  final double totalOwed;
  final double carryForwardIn;
  final double netBalance;

  String get displayName =>
      fullName.isNotEmpty ? fullName : (username.isNotEmpty ? username : 'Member');

  bool get owesMoney => netBalance > 0.01;
  bool get isOwedMoney => netBalance < -0.01;
}

class Settlement {
  const Settlement({
    required this.houseId,
    required this.cycleId,
    required this.totalFoodCost,
    required this.totalFixedCost,
    required this.totalOtherCost,
    required this.totalMealCount,
    required this.mealRate,
    required this.memberSummaries,
    this.computedAt,
    this.calculationEndDate,
  });

  final String houseId;
  final String cycleId;
  final double totalFoodCost;
  final double totalFixedCost;
  final double totalOtherCost;
  final double totalMealCount;
  final double mealRate;
  final List<MemberSettlementSummary> memberSummaries;
  final DateTime? computedAt;
  final DateTime? calculationEndDate;

  double get totalExpenses => totalFoodCost + totalFixedCost + totalOtherCost;
}
