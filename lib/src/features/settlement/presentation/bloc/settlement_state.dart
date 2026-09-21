part of 'settlement_bloc.dart';

enum SettlementPhase {
  dateRange,
  costSelection,
  summary,
  done,
}

final class SettlementState {
  const SettlementState({
    this.houseId = '',
    this.isAdmin = false,
    this.phase = SettlementPhase.dateRange,
    this.fromDate,
    this.toDate,
    this.isLoading = false,
    this.isFinalising = false,
    this.isLoadingHistory = false,
    this.draft,
    this.selectedCostIds = const {},
    this.previewSettlement,
    this.finalSettlement,
    this.settlementHistory = const [],
    this.errorMessage,
  });

  final String houseId;
  final bool isAdmin;
  final SettlementPhase phase;
  final DateTime? fromDate;
  final DateTime? toDate;
  final bool isLoading;
  final bool isFinalising;
  final bool isLoadingHistory;
  final SettlementDraft? draft;
  final Map<String, bool> selectedCostIds;
  final Settlement? previewSettlement;
  final Settlement? finalSettlement;
  final List<Settlement> settlementHistory;
  final String? errorMessage;

  /// IDs of costs the user kept checked.
  List<String> get includedCostIds => selectedCostIds.entries
      .where((e) => e.value)
      .map((e) => e.key)
      .toList();

  /// Total amount of selected costs.
  double get selectedTotal {
    if (draft == null) return 0;
    return draft!.allCosts
        .where((c) => selectedCostIds[c.id] == true)
        .fold(0, (sum, c) => sum + c.amount);
  }

  /// Per-category selection state: true=all, false=none, null=partial.
  bool? categoryCheckState(String categoryId, List<Cost> costs) {
    final inCat = costs.where(
      (c) => (c.categoryId ?? 'uncategorised') == categoryId,
    );
    if (inCat.isEmpty) return false;
    final checkedCount =
        inCat.where((c) => selectedCostIds[c.id] == true).length;
    if (checkedCount == 0) return false;
    if (checkedCount == inCat.length) return true;
    return null; // partial
  }

  SettlementState copyWith({
    String? houseId,
    bool? isAdmin,
    SettlementPhase? phase,
    DateTime? fromDate,
    DateTime? toDate,
    bool? isLoading,
    bool? isFinalising,
    bool? isLoadingHistory,
    SettlementDraft? draft,
    Map<String, bool>? selectedCostIds,
    Settlement? previewSettlement,
    Settlement? finalSettlement,
    List<Settlement>? settlementHistory,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SettlementState(
      houseId: houseId ?? this.houseId,
      isAdmin: isAdmin ?? this.isAdmin,
      phase: phase ?? this.phase,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      isLoading: isLoading ?? this.isLoading,
      isFinalising: isFinalising ?? this.isFinalising,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      draft: draft ?? this.draft,
      selectedCostIds: selectedCostIds ?? this.selectedCostIds,
      previewSettlement: previewSettlement ?? this.previewSettlement,
      finalSettlement: finalSettlement ?? this.finalSettlement,
      settlementHistory: settlementHistory ?? this.settlementHistory,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
