import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardSummary getDashboardSummary,
    required GetSprints getSprints,
  })  : _getDashboardSummary = getDashboardSummary,
        _getSprints = getSprints,
        super(DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    on<DashboardMonthChanged>(_onMonthChanged);
    on<DashboardHouseFilterChanged>(_onHouseChanged);
    on<DashboardCycleChanged>(_onCycleChanged);
  }

  final GetDashboardSummary _getDashboardSummary;
  final GetSprints _getSprints;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.selectedHouseId != null) {
      await _loadCyclesAndData(state.selectedHouseId!, emit);
    } else {
      await _load(emit);
    }
  }

  Future<void> _onMonthChanged(
    DashboardMonthChanged event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(selectedMonth: event.month));
    await _load(emit);
  }

  Future<void> _onHouseChanged(
    DashboardHouseFilterChanged event,
    Emitter<DashboardState> emit,
  ) async {
    final houseId = event.houseId;
    if (houseId == null) {
      emit(state.copyWith(
        selectedHouseId: null,
        clearHouse: true,
        cycles: [],
        clearCycle: true,
      ));
      await _load(emit);
      return;
    }

    emit(state.copyWith(
      selectedHouseId: houseId,
      status: DashboardStatus.loading,
    ));

    await _loadCyclesAndData(houseId, emit);
  }

  Future<void> _loadCyclesAndData(
    String houseId,
    Emitter<DashboardState> emit,
  ) async {
    // 1. Fetch cycles for this house
    final sprintsRes = await handleFutureRequest<List<Sprint>>(
      request: () => _getSprints(houseId),
      debugger: ControllerDebugger(),
    );

    final cycles = sprintsRes ?? [];
    // Select active cycle: prefer 'open' cycle, else the first cycle
    final activeCycle = cycles.isNotEmpty
        ? cycles.firstWhere(
            (c) => c.status == SprintStatus.open,
            orElse: () => cycles.first,
          )
        : null;

    emit(state.copyWith(
      selectedHouseId: houseId,
      cycles: cycles,
      selectedCycle: activeCycle,
      clearCycle: activeCycle == null,
    ));

    await _load(emit);
  }

  Future<void> _onCycleChanged(
    DashboardCycleChanged event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(selectedCycle: event.cycle));
    await _load(emit);
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));

    final monthStr = DateFormat('yyyy-MM').format(state.selectedMonth);
    final cycle = state.selectedCycle;

    final summary = await handleFutureRequest<DashboardSummary>(
      request: () => _getDashboardSummary(
        GetDashboardSummaryParams(
          houseId: state.selectedHouseId,
          cycleId: cycle?.id,
          startDate: cycle?.startDate,
          endDate: cycle?.endDate,
          month: monthStr,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: DashboardStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      onSuccess: (data) {
        emit(
          state.copyWith(
            status: DashboardStatus.loaded,
            summary: data,
            clearError: true,
          ),
        );
      },
    );

    if (summary == null && state.status == DashboardStatus.loading) {
      emit(state.copyWith(status: DashboardStatus.failure));
    }
  }
}
