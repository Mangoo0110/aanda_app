enum BalanceResolutionType {
  carryForward,
  miscellaneous,
}

extension BalanceResolutionTypeX on BalanceResolutionType {
  String get value => switch (this) {
        BalanceResolutionType.carryForward => 'carry_forward',
        BalanceResolutionType.miscellaneous => 'miscellaneous',
      };

  static BalanceResolutionType? fromString(String? val) => switch (val) {
        'carry_forward' => BalanceResolutionType.carryForward,
        'miscellaneous' => BalanceResolutionType.miscellaneous,
        _ => null,
      };

  String get displayName => switch (this) {
        BalanceResolutionType.carryForward => 'Carry Forward to Next Cycle',
        BalanceResolutionType.miscellaneous => 'Miscellaneous Adjustment',
      };
}

class MemberResolutionParams {
  const MemberResolutionParams({
    required this.userId,
    required this.resolutionType,
    this.resolutionReason,
  });

  final String userId;
  final BalanceResolutionType resolutionType;
  final String? resolutionReason;
}

class MemberSettlementSummary {
  const MemberSettlementSummary({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatarUrl,
    required this.totalMeals,
    required this.weightedMeals,
    required this.foodCharge,
    required this.fixedShare,
    required this.otherShare,
    required this.totalPaid,
    required this.totalOwed,
    required this.carryForwardIn,
    required this.netBalance,
    this.advanceDeposits = 0.0,
    this.settlementDeposits = 0.0,
    this.finalBalance = 0.0,
    this.resolutionType,
    this.resolutionReason,
    this.carryForwardReference,
  });

  final String userId;
  final String username;
  final String fullName;
  final String? avatarUrl;
  final double totalMeals;
  final double weightedMeals;
  final double foodCharge;
  final double fixedShare;
  final double otherShare;
  final double totalPaid; // Expenses paid by member during the period
  final double totalOwed; // Gross cost share of this member
  final double carryForwardIn; // Debt (positive) or credit (negative) from prior cycle
  final double netBalance; // Calculated statement payable before post-settlement deposits
  final double advanceDeposits; // Cash advance deposits during month
  final double settlementDeposits; // Cash/bKash paid during collection
  final double finalBalance; // Remaining balance after collections
  final BalanceResolutionType? resolutionType;
  final String? resolutionReason;
  final String? carryForwardReference;

  String get displayName => fullName.isNotEmpty
      ? fullName
      : (username.isNotEmpty ? username : 'Member');

  /// Net deposit = (Expenses paid + Cash advances) - Prior carry forward
  double get netDeposit => (totalPaid + advanceDeposits) - carryForwardIn;

  /// Amount member owes the house on the published statement
  double get payable => totalOwed - netDeposit;

  /// Remaining amount after post-calculation collections
  double get remainingDue => payable - settlementDeposits;

  bool get owesMoney => remainingDue > 0.01;
  bool get isOwedMoney => remainingDue < -0.01;
}

enum SettlementStatus { draft, published, finalised }

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
