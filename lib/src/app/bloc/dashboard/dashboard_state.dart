part of 'dashboard_bloc.dart';

final class DashboardState {
  const DashboardState({
    required this.accountName,
    this.isAccountMenuOpen = false,
    this.isLoggingOut = false,
    this.errorMessage,
    this.effect,
  });

  factory DashboardState.initial({required String accountName}) {
    return DashboardState(accountName: accountName);
  }

  final String accountName;
  final bool isAccountMenuOpen;
  final bool isLoggingOut;
  final String? errorMessage;
  final DashboardEffect? effect;

  DashboardState copyWith({
    String? accountName,
    bool? isAccountMenuOpen,
    bool? isLoggingOut,
    String? errorMessage,
    DashboardEffect? effect,
    bool clearError = false,
    bool clearEffect = false,
  }) {
    return DashboardState(
      accountName: accountName ?? this.accountName,
      isAccountMenuOpen: isAccountMenuOpen ?? this.isAccountMenuOpen,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
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
