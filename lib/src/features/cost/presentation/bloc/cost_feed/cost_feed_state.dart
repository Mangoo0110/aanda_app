part of 'cost_feed_bloc.dart';

enum CostFeedStatus { initial, loading, loaded, failure }

final class CostFeedState {
  CostFeedState({
    this.status = CostFeedStatus.initial,
    this.costs = const [],
    this.selectedScope,
    DateTime? selectedMonth,
    this.selectedHouseId,
    this.errorMessage,
  }) : selectedMonth = selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  final CostFeedStatus status;
  final List<Cost> costs;
  final CostScope? selectedScope;
  final DateTime selectedMonth;
  final String? selectedHouseId;
  final String? errorMessage;

  bool get isLoading => status == CostFeedStatus.loading;

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

  CostFeedState copyWith({
    CostFeedStatus? status,
    List<Cost>? costs,
    CostScope? selectedScope,
    bool clearScope = false,
    DateTime? selectedMonth,
    String? selectedHouseId,
    bool clearHouse = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CostFeedState(
      status: status ?? this.status,
      costs: costs ?? this.costs,
      selectedScope: clearScope ? null : (selectedScope ?? this.selectedScope),
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedHouseId:
          clearHouse ? null : (selectedHouseId ?? this.selectedHouseId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
