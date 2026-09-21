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

  String get displayName => fullName.isNotEmpty
      ? fullName
      : (username.isNotEmpty ? username : 'Member');

  bool get owesMoney => netBalance > 0.01;
  bool get isOwedMoney => netBalance < -0.01;
}

enum SettlementStatus { draft, finalised }

class Settlement {
  const Settlement({
    required this.houseId,
    this.cycleId,
    required this.fromDate,
    required this.toDate,
    required this.totalFoodCost,
    required this.totalFixedCost,
    required this.totalOtherCost,
    required this.totalMealCount,
    required this.mealRate,
    required this.memberSummaries,
    this.status = SettlementStatus.finalised,
    this.computedAt,
    this.settlementId,
    this.includedCostIds = const [],
  });

  final String houseId;
  final String? cycleId;
  final DateTime fromDate;
  final DateTime toDate;
  final double totalFoodCost;
  final double totalFixedCost;
  final double totalOtherCost;
  final double totalMealCount;
  final double mealRate;
  final List<MemberSettlementSummary> memberSummaries;
  final SettlementStatus status;
  final DateTime? computedAt;
  final String? settlementId;
  final List<String> includedCostIds;

  double get totalExpenses => totalFoodCost + totalFixedCost + totalOtherCost;

  String get dateRangeLabel {
    String fmt(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';
    return '${fmt(fromDate)} – ${fmt(toDate)}';
  }

  static String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return m >= 1 && m <= 12 ? months[m] : '';
  }
}
