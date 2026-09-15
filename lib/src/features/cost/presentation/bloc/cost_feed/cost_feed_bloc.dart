import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';

part 'cost_feed_event.dart';
part 'cost_feed_state.dart';

final class CostFeedBloc extends Bloc<CostFeedEvent, CostFeedState> {
  CostFeedBloc({
    required GetCosts getCosts,
    required DeleteCost deleteCost,
  }) : _getCosts = getCosts,
       _deleteCost = deleteCost,
       super(CostFeedState()) {
    on<CostFeedStarted>(_onStarted);
    on<CostFeedRefreshRequested>(_onRefresh);
    on<CostFeedScopeFilterChanged>(_onScopeChanged);
    on<CostFeedPayerFilterChanged>(_onPayerChanged);
    on<CostFeedMonthChanged>(_onMonthChanged);
    on<CostFeedHouseFilterChanged>(_onHouseChanged);
    on<CostFeedDeleted>(_onDeleted);
  }

  final GetCosts _getCosts;
  final DeleteCost _deleteCost;

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
    emit(state.copyWith(selectedScope: event.scope, clearScope: event.scope == null));
    await _load(emit);
  }

  void _onPayerChanged(
    CostFeedPayerFilterChanged event,
    Emitter<CostFeedState> emit,
  ) {
    emit(state.copyWith(
      selectedPayerId: event.payerId,
      clearPayer: event.payerId == null,
    ));
  }

  Future<void> _onMonthChanged(
    CostFeedMonthChanged event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(state.copyWith(selectedMonth: event.month));
    await _load(emit);
  }

  Future<void> _onHouseChanged(
    CostFeedHouseFilterChanged event,
    Emitter<CostFeedState> emit,
  ) async {
    emit(state.copyWith(selectedHouseId: event.houseId, clearHouse: event.houseId == null));
    await _load(emit);
  }

  Future<void> _onDeleted(
    CostFeedDeleted event,
    Emitter<CostFeedState> emit,
  ) async {
    final response = await _deleteCost(DeleteCostParams(costId: event.costId));
    if (response.success) {
      final updated = state.costs.where((c) => c.id != event.costId).toList();
      emit(state.copyWith(costs: updated));
    } else {
      emit(state.copyWith(errorMessage: response.message));
    }
  }

  Future<void> _load(Emitter<CostFeedState> emit) async {
    emit(state.copyWith(status: CostFeedStatus.loading, clearError: true));

    final month = state.selectedMonth;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    final response = await _getCosts(
      GetCostsParams(
        houseId: state.selectedHouseId,
        scope: state.selectedScope,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    if (!response.success || response.data == null) {
      emit(
        state.copyWith(
          status: CostFeedStatus.failure,
          errorMessage: response.message,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: CostFeedStatus.loaded,
        costs: response.data,
        clearError: true,
      ),
    );
  }
}
