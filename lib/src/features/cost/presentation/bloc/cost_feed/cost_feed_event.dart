part of 'cost_feed_bloc.dart';

sealed class CostFeedEvent {
  const CostFeedEvent();
}

final class CostFeedStarted extends CostFeedEvent {
  const CostFeedStarted();
}

final class CostFeedRefreshRequested extends CostFeedEvent {
  const CostFeedRefreshRequested();
}

final class CostFeedScopeFilterChanged extends CostFeedEvent {
  const CostFeedScopeFilterChanged(this.scope);
  final CostScope? scope; // null means All
}

final class CostFeedPayerFilterChanged extends CostFeedEvent {
  const CostFeedPayerFilterChanged(this.payerId);
  final String? payerId; // null means All Payers
}

final class CostFeedCategoryFilterChanged extends CostFeedEvent {
  const CostFeedCategoryFilterChanged(this.categoryId);
  final String? categoryId; // null means All Categories
}

final class CostFeedSprintSelected extends CostFeedEvent {
  const CostFeedSprintSelected(this.sprint);
  final Sprint? sprint;
}

final class CostFeedFiltersApplied extends CostFeedEvent {
  const CostFeedFiltersApplied({
    this.sprint,
    this.payerId,
    this.categoryId,
    this.scope,
  });

  final Sprint? sprint;
  final String? payerId;
  final String? categoryId;
  final CostScope? scope;
}

final class CostFeedFiltersCleared extends CostFeedEvent {
  const CostFeedFiltersCleared();
}

final class CostFeedMonthChanged extends CostFeedEvent {
  const CostFeedMonthChanged(this.month);
  final DateTime month;
}

final class CostFeedHouseFilterChanged extends CostFeedEvent {
  const CostFeedHouseFilterChanged(this.houseId);
  final String? houseId;
}

final class CostFeedDeleted extends CostFeedEvent {
  const CostFeedDeleted(this.costId);
  final String costId;
}
