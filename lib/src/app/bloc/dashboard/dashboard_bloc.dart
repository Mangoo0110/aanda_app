import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';
import 'package:aanda/src/features/entry/domain/params/delete_all_entry.dart';
import 'package:aanda/src/features/entry/domain/params/get_entry_total_amount_params.dart';
import 'package:aanda/src/features/entry/domain/usecases/delete_all_entry.dart';
import 'package:aanda/src/features/entry/domain/usecases/get_entry_total_amount.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required String accountName,
    required Logout logout,
    required DeleteCurrentAccount deleteCurrentAccount,
    required DeleteAllEntry deleteAllEntry,
    required GetEntryTotalAmount getEntryTotalAmount,
  }) : _logout = logout,
       _deleteCurrentAccount = deleteCurrentAccount,
       _deleteAllEntry = deleteAllEntry,
       _getEntryTotalAmount = getEntryTotalAmount,
       super(DashboardState.initial(accountName: accountName)) {
    on<DashboardStarted>(_onStarted);
    on<DashboardTotalsRefreshRequested>(_onTotalsRefreshRequested);
    on<DashboardAccountMenuToggled>(_onAccountMenuToggled);
    on<DashboardAccountMenuClosed>(_onAccountMenuClosed);
    on<DashboardThemePressed>(_onThemePressed);
    on<DashboardLogoutPressed>(_onLogoutPressed);
    on<DashboardDeleteAccountPressed>(_onDeleteAccountPressed);
    on<DashboardDeleteAccountConfirmed>(_onDeleteAccountConfirmed);
    on<DashboardEffectHandled>(_onEffectHandled);
  }

  final Logout _logout;
  final DeleteCurrentAccount _deleteCurrentAccount;
  final DeleteAllEntry _deleteAllEntry;
  final GetEntryTotalAmount _getEntryTotalAmount;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async {
    await _refreshTotals(emit);
  }

  Future<void> _onTotalsRefreshRequested(
    DashboardTotalsRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    await _refreshTotals(emit);
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
    emit(
      state.copyWith(
        isAccountMenuOpen: false,
        isLoggingOut: true,
        clearError: true,
      ),
    );
    final response = await _logout(const NoParams());
    if (!response.success) {
      emit(state.copyWith(isLoggingOut: false, errorMessage: response.message));
      return;
    }

    emit(state.copyWith(isLoggingOut: false, clearError: true));
  }

  void _onDeleteAccountPressed(
    DashboardDeleteAccountPressed event,
    Emitter<DashboardState> emit,
  ) {
    emit(
      state.copyWith(
        isAccountMenuOpen: false,
        effect: const DashboardConfirmDeleteAccountEffect(),
      ),
    );
  }

  Future<void> _onDeleteAccountConfirmed(
    DashboardDeleteAccountConfirmed event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(isDeletingAccount: true, clearError: true));
    final entriesResponse = await _deleteAllEntry(
      DeleteAllEntryParam(owner: state.accountName),
    );
    if (!entriesResponse.success) {
      event.result.complete(false);
      emit(
        state.copyWith(
          isDeletingAccount: false,
          errorMessage: entriesResponse.message,
        ),
      );
      return;
    }

    final accountResponse = await _deleteCurrentAccount(const NoParams());
    if (!accountResponse.success) {
      event.result.complete(false);
      emit(
        state.copyWith(
          isDeletingAccount: false,
          errorMessage: accountResponse.message,
        ),
      );
      return;
    }

    event.result.complete(true);
    emit(state.copyWith(isDeletingAccount: false, clearError: true));
  }

  void _onEffectHandled(
    DashboardEffectHandled event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(clearEffect: true));
  }

  Future<void> _refreshTotals(Emitter<DashboardState> emit) async {
    emit(state.copyWith(isSyncingTotals: true, clearError: true));
    final response = await _getEntryTotalAmount(
      GetEntryTotalAmountParams.thisMonth(owner: state.accountName),
    );
    if (!response.success || response.data == null) {
      emit(
        state.copyWith(isSyncingTotals: false, errorMessage: response.message),
      );
      return;
    }

    emit(
      state.copyWith(
        monthAmount: response.data!,
        isSyncingTotals: false,
        lastSyncedAt: DateTime.now(),
        clearError: true,
      ),
    );
  }
}
