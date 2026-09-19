import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'cost_feed_event.dart';
part 'cost_feed_state.dart';

final class CostFeedBloc extends Bloc<CostFeedEvent, CostFeedState> {
  CostFeedBloc({
    required GetCosts getCosts,
    required DeleteCost deleteCost,
    GetCostCategories? getCostCategories,
    GetSprints? getSprints,
    String? initialHouseId,
    String? initialCycleId,
  }) : _getCosts = getCosts,
       _deleteCost = deleteCost,
       _getCostCategories = getCostCategories,
       _getSprints = getSprints,
       super(CostFeedState(selectedHouseId: initialHouseId)) {
    on<CostFeedStarted>(_onStarted);
    on<CostFeedRefreshRequested>(_onRefresh);
    on<CostFeedScopeFilterChanged>(_onScopeChanged);
    on<CostFeedPayerFilterChanged>(_onPayerChanged);
    on<CostFeedCategoryFilterChanged>(_onCategoryChanged);
    on<CostFeedSprintSelected>(_onSprintSelected);
    on<CostFeedFiltersApplied>(_onFiltersApplied);
    on<CostFeedFiltersCleared>(_onFiltersCleared);
    on<CostFeedMonthChanged>(_onMonthChanged);
    on<CostFeedHouseFilterChanged>(_onHouseChanged);
    on<CostFeedDeleted>(_onDeleted);
  }

  final GetCosts _getCosts;
  final DeleteCost _deleteCost;
  final GetCostCategories? _getCostCategories;
  final GetSprints? _getSprints;

  Future<void> _onStarted(
    CostFeedStarted event,
    Emitter<CostFeedState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    CostFeedRefreshRequested event,
    Emitter<CostFeedState> emit,
  ) async => _load(emit);

  Future<void> _onScopeChanged(
    CostFeedScopeFilterChanged event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedScope: event.scope,
        clearScope: event.scope == null,
      ),
    );
    await _load(emit);
  }

  void _onPayerChanged(
    CostFeedPayerFilterChanged event,
    Emitter<CostFeedState> emit,
  ) {
    emit(
      state.copyWith(
        selectedPayerId: event.payerId,
        clearPayer: event.payerId == null,
      ),
    );
  }

  void _onCategoryChanged(
    CostFeedCategoryFilterChanged event,
    Emitter<CostFeedState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        clearCategory: event.categoryId == null,
      ),
    );
  }

  Future<void> _onSprintSelected(
    CostFeedSprintSelected event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedSprint: event.sprint,
        clearSprint: event.sprint == null,
      ),
    );
    await _load(emit);
  }

  Future<void> _onFiltersApplied(
    CostFeedFiltersApplied event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedSprint: event.sprint,
        clearSprint: event.sprint == null,
        selectedPayerId: event.payerId,
        clearPayer: event.payerId == null,
        selectedCategoryId: event.categoryId,
        clearCategory: event.categoryId == null,
        selectedScope: event.scope,
        clearScope: event.scope == null,
      ),
    );
    await _load(emit);
  }

  Future<void> _onFiltersCleared(
    CostFeedFiltersCleared event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        clearSprint: true,
        clearPayer: true,
        clearCategory: true,
        clearScope: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onMonthChanged(
    CostFeedMonthChanged event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(state.copyWith(selectedMonth: event.month, clearSprint: true));
    await _load(emit);
  }

  Future<void> _onHouseChanged(
    CostFeedHouseFilterChanged event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedHouseId: event.houseId,
        clearHouse: event.houseId == null,
        clearSprint: true,
      ),
    );
    await _load(emit);
  }

  Future<void> _onDeleted(
    CostFeedDeleted event,
    Emitter<CostFeedState> emit,
  ) async {
    await handleFutureRequest<void>(
      request: () => _deleteCost(DeleteCostParams(costId: event.costId)),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(errorMessage: failure.message));
      },
      onSuccess: (_) {
        final updated = state.costs.where((c) => c.id != event.costId).toList();
        emit(state.copyWith(costs: updated));
      },
    );
  }

  Future<void> _load(Emitter<CostFeedState> emit) async {
    emit(state.copyWith(status: CostFeedStatus.loading, clearError: true));

    // 1. Load categories if not loaded
    List<CostCategory> categories = state.categories;
    if (categories.isEmpty && _getCostCategories != null) {
      final cats = await handleFutureRequest<List<CostCategory>>(
        request: () => _getCostCategories(
          GetCostCategoriesParams(houseId: state.selectedHouseId),
        ),
        debugger: ControllerDebugger(),
      );
      if (cats != null) categories = cats;
    }

    // 2. Load sprints if house selected or user has house
    List<Sprint> sprints = state.sprints;
    if (_getSprints != null &&
        state.selectedHouseId != null &&
        sprints.isEmpty) {
      final sp = await handleFutureRequest<List<Sprint>>(
        request: () => _getSprints(state.selectedHouseId!),
        debugger: ControllerDebugger(),
      );
      if (sp != null) sprints = sp;
    }

    // Determine date filter: Sprint dates take precedence over calendar month
    DateTime startDate;
    DateTime endDate;

    if (state.selectedSprint != null) {
      startDate = state.selectedSprint!.startDate;
      // Open cycle has no end date — use end of today as effective boundary
      final sprintEnd = state.selectedSprint!.endDate ?? DateTime.now();
      endDate = DateTime(
        sprintEnd.year,
        sprintEnd.month,
        sprintEnd.day,
        23,
        59,
        59,
      );
    } else {
      final month = state.selectedMonth;
      startDate = DateTime(month.year, month.month, 1);
      endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    }

    final result = await handleFutureRequest<List<Cost>>(
      request: () => _getCosts(
        GetCostsParams(
          startDate: startDate,
          endDate: endDate,
          scope: state.selectedScope,
          houseId: state.selectedHouseId,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: CostFeedStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (result != null) {
      emit(
        state.copyWith(
          status: CostFeedStatus.loaded,
          costs: result,
          categories: categories,
          sprints: sprints,
          clearError: true,
        ),
      );
    } else {
      if (state.status == CostFeedStatus.loading) {
        emit(state.copyWith(status: CostFeedStatus.failure));
      }
    }
  }
}
