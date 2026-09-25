part of 'settlement_bloc.dart';

sealed class SettlementEvent {}

final class SettlementStarted extends SettlementEvent {
  SettlementStarted({required this.houseId, required this.isAdmin});
  final String houseId;
  final bool isAdmin;
}

final class SettlementDateRangeSet extends SettlementEvent {
  SettlementDateRangeSet({required this.fromDate, required this.toDate});
  final DateTime fromDate;
  final DateTime toDate;
}

final class SettlementCostToggled extends SettlementEvent {
  SettlementCostToggled({required this.costId, required this.selected});
  final String costId;
  final bool selected;
}

final class SettlementCategoryToggled extends SettlementEvent {
  SettlementCategoryToggled({
    required this.categoryId,
    required this.selected,
  });
  final String categoryId;
  final bool selected;
}

final class SettlementPreviewRequested extends SettlementEvent {}

final class SettlementPublishRequested extends SettlementEvent {}

final class SettlementDepositRecordRequested extends SettlementEvent {
  SettlementDepositRecordRequested({
    required this.userId,
    required this.amount,
    this.note,
  });
  final String userId;
  final double amount;
  final String? note;
}

final class SettlementFinaliseRequested extends SettlementEvent {}

final class SettlementFinaliseWithResolutionsRequested extends SettlementEvent {
  SettlementFinaliseWithResolutionsRequested({
    required this.resolutions,
  });
  final List<MemberResolutionParams> resolutions;
}

final class SettlementHistoryRequested extends SettlementEvent {
  SettlementHistoryRequested({required this.houseId});
  final String houseId;
}

final class SettlementReset extends SettlementEvent {}
