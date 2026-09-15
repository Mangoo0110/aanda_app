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
