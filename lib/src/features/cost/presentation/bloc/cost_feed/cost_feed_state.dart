part of 'cost_feed_bloc.dart';

enum CostFeedStatus { initial, loading, loaded, failure }

final class CostFeedState {
  CostFeedState({
    this.status = CostFeedStatus.initial,
    this.costs = const [],
    this.sprints = const [],
    this.selectedSprint,
    this.categories = const [],
    this.selectedCategoryId,
    this.selectedScope,
    DateTime? selectedMonth,
    this.selectedHouseId,
    this.selectedPayerId,
    this.errorMessage,
  }) : selectedMonth =
           selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  final CostFeedStatus status;
  final List<Cost> costs;
  final List<Sprint> sprints;
  final Sprint? selectedSprint;
  final List<CostCategory> categories;
  final String? selectedCategoryId;
  final CostScope? selectedScope;
  final DateTime selectedMonth;
  final String? selectedHouseId;
  final String? selectedPayerId;
  final String? errorMessage;

  bool get isLoading => status == CostFeedStatus.loading;

  /// Costs filtered by payer and category if set.
  List<Cost> get displayCosts {
    var list = costs;
    if (selectedPayerId != null) {
      list = list.where((c) => c.paidBy == selectedPayerId).toList();
    }
    if (selectedCategoryId != null) {
      list = list.where((c) => c.categoryId == selectedCategoryId).toList();
    }
    return list;
  }

  /// Number of active filters applied
  int get activeFiltersCount {
    int count = 0;
    if (selectedPayerId != null) count++;
    if (selectedCategoryId != null) count++;
    if (selectedScope != null) count++;
    if (selectedSprint != null) count++;
    return count;
  }

  /// Total sum across all currently loaded costs.
  double get totalSpent => costs.fold(0.0, (sum, c) => sum + c.amount);

  /// Personal sum across loaded costs.
  double get personalSpent => costs
      .where((c) => c.costScope == CostScope.personal)
      .fold(0.0, (sum, c) => sum + c.amount);

  /// Shared sum across loaded costs.
  double get sharedSpent => costs
      .where((c) => c.costScope == CostScope.shared)
      .fold(0.0, (sum, c) => sum + c.amount);

  /// Total amount paid out of pocket by the specified user.
  double myTotalSpent(String? userId) {
    if (userId == null) return 0.0;
    return costs
        .where((c) => c.paidBy == userId)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  /// Personal amount paid out of pocket by the specified user.
  double myPersonalSpent(String? userId) {
    if (userId == null) return 0.0;
    return costs
        .where((c) => c.paidBy == userId && c.costScope == CostScope.personal)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  /// Shared amount paid out of pocket by the specified user.
  double mySharedSpent(String? userId) {
    if (userId == null) return 0.0;
    return costs
        .where((c) => c.paidBy == userId && c.costScope == CostScope.shared)
        .fold(0.0, (sum, c) => sum + c.amount);
  }

  /// The latest personal costs entered by the specified user for themselves.
  List<Cost> myRecentCosts(String? userId, [int count = 3]) {
    if (userId == null) return const [];
    return costs
        .where((c) => c.paidBy == userId && c.costScope == CostScope.personal)
        .take(count)
        .toList();
  }

  /// Distinct list of payers in loaded costs (id and display name).
  List<({String id, String name})> get uniquePayers {
    final seen = <String>{};
    final list = <({String id, String name})>[];
    for (final c in costs) {
      if (seen.add(c.paidBy)) {
        list.add((
          id: c.paidBy,
          name: c.payerName?.isNotEmpty == true ? c.payerName! : 'Member',
        ));
      }
    }
    return list;
  }

  CostFeedState copyWith({
    CostFeedStatus? status,
    List<Cost>? costs,
    List<Sprint>? sprints,
    Sprint? selectedSprint,
    bool clearSprint = false,
    List<CostCategory>? categories,
    String? selectedCategoryId,
    bool clearCategory = false,
    CostScope? selectedScope,
    bool clearScope = false,
    DateTime? selectedMonth,
    String? selectedHouseId,
    bool clearHouse = false,
    String? selectedPayerId,
    bool clearPayer = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CostFeedState(
      status: status ?? this.status,
      costs: costs ?? this.costs,
      sprints: sprints ?? this.sprints,
      selectedSprint: clearSprint
          ? null
          : (selectedSprint ?? this.selectedSprint),
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      selectedScope: clearScope ? null : (selectedScope ?? this.selectedScope),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedHouseId: clearHouse
          ? null
          : (selectedHouseId ?? this.selectedHouseId),
      selectedPayerId: clearPayer
          ? null
          : (selectedPayerId ?? this.selectedPayerId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
