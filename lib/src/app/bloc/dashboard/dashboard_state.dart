part of 'dashboard_bloc.dart';

final class DashboardState {
  const DashboardState({
    required this.accountName,
    this.monthAmount = 0,
    this.isSyncingTotals = false,
    this.lastSyncedAt,
    this.isAccountMenuOpen = false,
    this.isLoggingOut = false,
    this.isDeletingAccount = false,
    this.errorMessage,
    this.effect,
  });

  factory DashboardState.initial({required String accountName}) {
    return DashboardState(accountName: accountName);
  }

  final String accountName;
  final double monthAmount;
  final bool isSyncingTotals;
  final DateTime? lastSyncedAt;
  final bool isAccountMenuOpen;
  final bool isLoggingOut;
  final bool isDeletingAccount;
  final String? errorMessage;
  final DashboardEffect? effect;

  DashboardState copyWith({
    String? accountName,
    double? monthAmount,
    bool? isSyncingTotals,
    DateTime? lastSyncedAt,
    bool? isAccountMenuOpen,
    bool? isLoggingOut,
    bool? isDeletingAccount,
    String? errorMessage,
    DashboardEffect? effect,
    bool clearError = false,
    bool clearEffect = false,
  }) {
    return DashboardState(
      accountName: accountName ?? this.accountName,
      monthAmount: monthAmount ?? this.monthAmount,
      isSyncingTotals: isSyncingTotals ?? this.isSyncingTotals,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isAccountMenuOpen: isAccountMenuOpen ?? this.isAccountMenuOpen,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      isDeletingAccount: isDeletingAccount ?? this.isDeletingAccount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      effect: clearEffect ? null : effect ?? this.effect,
    );
  }
}

sealed class DashboardEffect {
  const DashboardEffect();
}

final class DashboardToggleThemeEffect extends DashboardEffect {
  const DashboardToggleThemeEffect();
}

final class DashboardConfirmDeleteAccountEffect extends DashboardEffect {
  const DashboardConfirmDeleteAccountEffect();
}
