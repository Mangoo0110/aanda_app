import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement_draft.dart';
import 'package:aanda/src/features/settlement/domain/usecases/settlement_usecases.dart';

part 'settlement_event.dart';
part 'settlement_state.dart';

final class SettlementBloc extends Bloc<SettlementEvent, SettlementState> {
  SettlementBloc({
    required PrepareSettlement prepareSettlement,
    required ComputeSettlement computeSettlement,
    required FinaliseSettlement finaliseSettlement,
    required GetSettlements getSettlements,
  })  : _prepareSettlement = prepareSettlement,
        _computeSettlement = computeSettlement,
        _finaliseSettlement = finaliseSettlement,
        _getSettlements = getSettlements,
        super(const SettlementState()) {
    on<SettlementStarted>(_onStarted);
    on<SettlementDateRangeSet>(_onDateRangeSet);
    on<SettlementCostToggled>(_onCostToggled);
    on<SettlementCategoryToggled>(_onCategoryToggled);
    on<SettlementPreviewRequested>(_onPreviewRequested);
    on<SettlementFinaliseRequested>(_onFinaliseRequested);
    on<SettlementHistoryRequested>(_onHistoryRequested);
    on<SettlementReset>(_onReset);
  }

  final PrepareSettlement _prepareSettlement;
  final ComputeSettlement _computeSettlement;
  final FinaliseSettlement _finaliseSettlement;
  final GetSettlements _getSettlements;

  Future<void> _onStarted(
    SettlementStarted event,
    Emitter<SettlementState> emit,
  ) async {
    // Set defaults: first day of current month → today
    final now = DateTime.now();
    final defaultFrom = DateTime(now.year, now.month, 1);
    emit(state.copyWith(
      houseId: event.houseId,
      isAdmin: event.isAdmin,
      phase: SettlementPhase.dateRange,
      fromDate: defaultFrom,
      toDate: now,
      clearError: true,
    ));
  }

  Future<void> _onDateRangeSet(
    SettlementDateRangeSet event,
    Emitter<SettlementState> emit,
  ) async {
    emit(state.copyWith(
      fromDate: event.fromDate,
      toDate: event.toDate,
      isLoading: true,
      clearError: true,
    ));

    final draft = await handleFutureRequest<SettlementDraft>(
      request: () => _prepareSettlement(
        PrepareSettlementParams(
          houseId: state.houseId,
          fromDate: event.fromDate,
          toDate: event.toDate,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
    );

    if (draft == null) return;

    // Default: all costs are selected
    final selected = {for (final c in draft.allCosts) c.id: true};

    emit(state.copyWith(
      isLoading: false,
      draft: draft,
      selectedCostIds: selected,
      phase: SettlementPhase.costSelection,
      clearError: true,
    ));
  }

  void _onCostToggled(
    SettlementCostToggled event,
    Emitter<SettlementState> emit,
  ) {
    final updated = Map<String, bool>.from(state.selectedCostIds);
    updated[event.costId] = event.selected;
    emit(state.copyWith(selectedCostIds: updated));
  }

  void _onCategoryToggled(
    SettlementCategoryToggled event,
    Emitter<SettlementState> emit,
  ) {
    final draft = state.draft;
    if (draft == null) return;

    final updated = Map<String, bool>.from(state.selectedCostIds);
    final categoryCosts = draft.allCosts
        .where((c) => (c.categoryId ?? 'uncategorised') == event.categoryId);

    for (final c in categoryCosts) {
      updated[c.id] = event.selected;
    }
    emit(state.copyWith(selectedCostIds: updated));
  }

  Future<void> _onPreviewRequested(
    SettlementPreviewRequested event,
    Emitter<SettlementState> emit,
  ) async {
    final costIds = state.includedCostIds;
    if (costIds.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Select at least one cost to preview.',
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, clearError: true));

    final settlement = await handleFutureRequest<Settlement>(
      request: () => _computeSettlement(
        ComputeSettlementParams(
          houseId: state.houseId,
          fromDate: state.fromDate!,
          toDate: state.toDate!,
          costIds: costIds,
          save: false,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      },
    );

    if (settlement == null) return;

    emit(state.copyWith(
      isLoading: false,
      previewSettlement: settlement,
      phase: SettlementPhase.summary,
      clearError: true,
    ));
  }

  Future<void> _onFinaliseRequested(
    SettlementFinaliseRequested event,
    Emitter<SettlementState> emit,
  ) async {
    final costIds = state.includedCostIds;
    if (costIds.isEmpty) return;

    emit(state.copyWith(isFinalising: true, clearError: true));

    final settlement = await handleFutureRequest<Settlement>(
      request: () => _finaliseSettlement(
        FinaliseSettlementParams(
          houseId: state.houseId,
          fromDate: state.fromDate!,
          toDate: state.toDate!,
          includedCostIds: costIds,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(isFinalising: false, errorMessage: failure.message));
      },
    );

    if (settlement == null) return;

    emit(state.copyWith(
      isFinalising: false,
      finalSettlement: settlement,
      phase: SettlementPhase.done,
      clearError: true,
    ));
  }

  Future<void> _onHistoryRequested(
    SettlementHistoryRequested event,
    Emitter<SettlementState> emit,
  ) async {
    emit(state.copyWith(isLoadingHistory: true, clearError: true));

    final settlements = await handleFutureRequest<List<Settlement>>(
      request: () => _getSettlements(
        GetSettlementsParams(houseId: event.houseId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(
          isLoadingHistory: false,
          errorMessage: failure.message,
        ));
      },
    );

    emit(state.copyWith(
      isLoadingHistory: false,
      settlementHistory: settlements ?? [],
    ));
  }

  void _onReset(SettlementReset event, Emitter<SettlementState> emit) {
    emit(const SettlementState());
  }
}
