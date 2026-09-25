import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/usecases/cost_usecases.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/domain/usecases/meal_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required GetDashboardSummary getDashboardSummary,
    required GetSprints getSprints,
    required GetHouseMembers getHouseMembers,
    required GetMealLogs getMealLogs,
    GetCosts? getCosts,
  })  : _getDashboardSummary = getDashboardSummary,
        _getSprints = getSprints,
        _getHouseMembers = getHouseMembers,
        _getMealLogs = getMealLogs,
        _getCosts = getCosts,
        super(DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    on<DashboardMonthChanged>(_onMonthChanged);
    on<DashboardHouseFilterChanged>(_onHouseChanged);
    on<DashboardCycleChanged>(_onCycleChanged);
  }

  final GetDashboardSummary _getDashboardSummary;
  final GetSprints _getSprints;
  final GetHouseMembers _getHouseMembers;
  final GetMealLogs _getMealLogs;
  final GetCosts? _getCosts;

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
        todayMealLogs: [],
        houseMembers: [],
        isTodayMealsLoading: false,
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
    Sprint? activeCycle;
    if (cycles.isNotEmpty) {
      for (final c in cycles) {
        if (c.status == SprintStatus.open) {
          activeCycle = c;
          break;
        }
      }
      activeCycle ??= cycles.first;
    }

    emit(state.copyWith(
      selectedHouseId: houseId,
      cycles: cycles,
      selectedCycle: activeCycle,
      clearCycle: activeCycle == null,
      isTodayMealsLoading: activeCycle != null,
    ));

    // Fetch members and today's meals if in shared house with active cycle
    if (activeCycle != null) {
      final cycle = activeCycle;
      final membersRes = await handleFutureRequest<List<HouseMember>>(
        request: () => _getHouseMembers(houseId),
        debugger: ControllerDebugger(),
      );
      final members = membersRes ?? [];

      final today = DateTime.now();
      final mealsRes = await handleFutureRequest<List<MealLog>>(
        request: () => _getMealLogs(
          GetMealLogsParams(
            houseId: houseId,
            cycleId: cycle.id,
            date: today,
          ),
        ),
        debugger: ControllerDebugger(),
      );
      final todayMeals = mealsRes ?? [];

      emit(state.copyWith(
        houseMembers: members,
        todayMealLogs: todayMeals,
        isTodayMealsLoading: false,
      ));
    } else {
      emit(state.copyWith(
        houseMembers: [],
        todayMealLogs: [],
        isTodayMealsLoading: false,
      ));
    }

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
            recentCosts: data.recentCosts,
            clearError: true,
          ),
        );
      },
    );

    if (_getCosts != null && summary != null) {
      DateTime startDate;
      DateTime endDate;
      if (cycle != null) {
        startDate = cycle.startDate;
        final sprintEnd = cycle.endDate ?? DateTime.now();
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

      final isPersonal = state.selectedHouseId == null;
      final costsRes = await handleFutureRequest<List<Cost>>(
        request: () => _getCosts(
          GetCostsParams(
            startDate: startDate,
            endDate: endDate,
            houseId: isPersonal ? null : state.selectedHouseId,
            scope: isPersonal ? CostScope.personal : CostScope.shared,
          ),
        ),
        debugger: ControllerDebugger(),
      );
      if (costsRes != null) {
        emit(state.copyWith(recentCosts: costsRes.take(10).toList()));
      }
    }

    if (summary == null && state.status == DashboardStatus.loading) {
      emit(state.copyWith(status: DashboardStatus.failure));
    }
  }
}
