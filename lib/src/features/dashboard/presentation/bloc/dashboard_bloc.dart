import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:aanda/src/features/dashboard/domain/usecases/dashboard_usecases.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

final class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({required GetDashboardSummary getDashboardSummary})
    : _getDashboardSummary = getDashboardSummary,
      super(DashboardState()) {
    on<DashboardStarted>(_onStarted);
    on<DashboardRefreshRequested>(_onRefresh);
    on<DashboardMonthChanged>(_onMonthChanged);
    on<DashboardHouseFilterChanged>(_onHouseChanged);
  }

  final GetDashboardSummary _getDashboardSummary;

  Future<void> _onStarted(
    DashboardStarted event,
    Emitter<DashboardState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async => _load(emit);

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
    emit(
      state.copyWith(
        selectedHouseId: event.houseId,
        clearHouse: event.houseId == null,
      ),
    );
    await _load(emit);
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    emit(state.copyWith(status: DashboardStatus.loading, clearError: true));

    final monthStr = DateFormat('yyyy-MM').format(state.selectedMonth);

    final summary = await handleFutureRequest<DashboardSummary>(
      request: () => _getDashboardSummary(
        GetDashboardSummaryParams(
          houseId: state.selectedHouseId,
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
