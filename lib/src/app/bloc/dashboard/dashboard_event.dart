part of 'dashboard_bloc.dart';

sealed class DashboardEvent {
  const DashboardEvent();
}

final class DashboardStarted extends DashboardEvent {
  const DashboardStarted();
}

final class DashboardTotalsRefreshRequested extends DashboardEvent {
  const DashboardTotalsRefreshRequested();
}

final class DashboardAccountMenuToggled extends DashboardEvent {
  const DashboardAccountMenuToggled();
}

final class DashboardAccountMenuClosed extends DashboardEvent {
  const DashboardAccountMenuClosed();
}

final class DashboardThemePressed extends DashboardEvent {
  const DashboardThemePressed();
}

final class DashboardLogoutPressed extends DashboardEvent {
  const DashboardLogoutPressed();
}

final class DashboardDeleteAccountPressed extends DashboardEvent {
  const DashboardDeleteAccountPressed();
}

final class DashboardDeleteAccountConfirmed extends DashboardEvent {
  const DashboardDeleteAccountConfirmed(this.result);

  final Completer<bool> result;
}

final class DashboardEffectHandled extends DashboardEvent {
  const DashboardEffectHandled();
}
