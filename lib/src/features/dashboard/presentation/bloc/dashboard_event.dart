part of 'dashboard_bloc.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

final class DashboardRefreshRequested extends DashboardEvent {
  const DashboardRefreshRequested();
}

final class DashboardMonthChanged extends DashboardEvent {
  const DashboardMonthChanged(this.month);
  final DateTime month;
}

final class DashboardHouseFilterChanged extends DashboardEvent {
  const DashboardHouseFilterChanged(this.houseId);
  final String? houseId;
}
