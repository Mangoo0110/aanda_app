import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Top-level dashboard bloc — handles logout and theme toggle.
///
/// Phase 2 will extend this to manage house context (selected house,
/// member list refresh, etc.).
final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required String accountName,
    required Logout logout,
  }) : _logout = logout,
       super(DashboardState.initial(accountName: accountName)) {
    on<DashboardStarted>(_onStarted);
    on<DashboardAccountMenuToggled>(_onAccountMenuToggled);
    on<DashboardAccountMenuClosed>(_onAccountMenuClosed);
    on<DashboardThemePressed>(_onThemePressed);
    on<DashboardLogoutPressed>(_onLogoutPressed);
    on<DashboardEffectHandled>(_onEffectHandled);
  }

  final Logout _logout;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    // Phase 2: load house list / active house.
  }

  void _onAccountMenuToggled(
    DashboardAccountMenuToggled event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(isAccountMenuOpen: !state.isAccountMenuOpen));
  }

  void _onAccountMenuClosed(
    DashboardAccountMenuClosed event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(isAccountMenuOpen: false));
  }

  void _onThemePressed(
    DashboardThemePressed event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        isAccountMenuOpen: false,
        effect: const DashboardToggleThemeEffect(),
      ),
    );
  }

  Future<void> _onLogoutPressed(
    DashboardLogoutPressed event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isAccountMenuOpen: false, isLoggingOut: true, clearError: true));
    final response = await _logout(const NoParams());
    if (!response.success) {
      emit(state.copyWith(isLoggingOut: false, errorMessage: response.message));
      return;
    }
    emit(state.copyWith(isLoggingOut: false, clearError: true));
  }

  void _onEffectHandled(
    DashboardEffectHandled event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(clearEffect: true));
  }
}
