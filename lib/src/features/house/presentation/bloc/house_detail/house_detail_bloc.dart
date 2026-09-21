import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_detail_event.dart';
part 'house_detail_state.dart';

final class HouseDetailBloc extends Bloc<HouseDetailEvent, HouseDetailState> {
  HouseDetailBloc({
    required String houseId,
    required GetHouseDetail getHouseDetail,
    required GetHouseInvite getHouseInvite,
    required RegenerateInviteCode regenerateInviteCode,
    required RemoveMember removeMember,
    required LeaveHouse leaveHouse,
    required GetSprintStats getSprintStats,
  }) : _getHouseDetail = getHouseDetail,
       _getHouseInvite = getHouseInvite,
       _regenerateInviteCode = regenerateInviteCode,
       _removeMember = removeMember,
       _leaveHouse = leaveHouse,
       _getSprintStats = getSprintStats,
       super(HouseDetailState(houseId: houseId)) {
    on<HouseDetailStarted>(_onStarted);
    on<HouseDetailRefreshRequested>(_onRefresh);
    on<HouseDetailRegenerateCodeRequested>(_onRegenerateCode);
    on<HouseDetailMemberRemoveRequested>(_onRemoveMember);
    on<HouseDetailLeaveRequested>(_onLeave);
  }

  final GetHouseDetail _getHouseDetail;
  final GetHouseInvite _getHouseInvite;
  final RegenerateInviteCode _regenerateInviteCode;
  final RemoveMember _removeMember;
  final LeaveHouse _leaveHouse;
  final GetSprintStats _getSprintStats;

  Future<void> _onStarted(
    HouseDetailStarted event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    HouseDetailRefreshRequested event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _onRegenerateCode(
    HouseDetailRegenerateCodeRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));

    final newInvite = await handleFutureRequest<HouseInvite>(
      request: () => _regenerateInviteCode(
        RegenerateInviteCodeParams(houseId: state.houseId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(isActioning: false, errorMessage: failure.message));
      },
    );

    if (newInvite == null) return;

    emit(
      state.copyWith(isActioning: false, invite: newInvite, clearError: true),
    );
  }

  Future<void> _onRemoveMember(
    HouseDetailMemberRemoveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));
    bool success = true;

    await handleFutureRequest<void>(
      request: () => _removeMember(
        RemoveMemberParams(houseId: state.houseId, userId: event.userId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        success = false;
        emit(state.copyWith(isActioning: false, errorMessage: failure.message));
      },
    );

    if (!success) return;

    emit(state.copyWith(isActioning: false, clearError: true));
    await _load(emit);
  }

  Future<void> _onLeave(
    HouseDetailLeaveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));
    bool success = true;

    await handleFutureRequest<void>(
      request: () => _leaveHouse(LeaveHouseParams(houseId: state.houseId)),
      debugger: ControllerDebugger(),
      onError: (failure) {
        success = false;
        emit(state.copyWith(isActioning: false, errorMessage: failure.message));
      },
    );

    if (!success) return;

    emit(state.copyWith(isActioning: false, clearError: true));
  }

  Future<void> _load(Emitter<HouseDetailState> emit) async {
    emit(state.copyWith(status: HouseDetailStatus.loading, clearError: true));

    // 1. Fetch house detail
    final house = await handleFutureRequest<House>(
      request: () =>
          _getHouseDetail(GetHouseDetailParams(houseId: state.houseId)),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseDetailStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (house == null) return;

    // 2. Fetch invite
    final invite = await handleFutureRequest<HouseInvite>(
      request: () =>
          _getHouseInvite(GetHouseInviteParams(houseId: state.houseId)),
      debugger: ControllerDebugger(),
    );

    emit(
      state.copyWith(
        status: HouseDetailStatus.loaded,
        house: house,
        invite: invite,
        clearError: true,
      ),
    );

    // 3. Load account stats (current month → today, no cycle needed)
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final stats = await handleFutureRequest<Map<String, dynamic>>(
      request: () => _getSprintStats(
        GetSprintStatsParams(
          houseId: state.houseId,
          cycleId: null,
          startDate: monthStart,
          endDate: now,
        ),
      ),
      debugger: ControllerDebugger(),
    );

    if (stats != null) {
      emit(state.copyWith(accountStats: stats));
    }
  }
}
