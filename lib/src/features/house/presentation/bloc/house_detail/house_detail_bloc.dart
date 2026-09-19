import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/settlement/domain/entities/settlement.dart';
import 'package:aanda/src/features/settlement/domain/usecases/settlement_usecases.dart';

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
    required GetSprints getSprints,
    required GetSprintStats getSprintStats,
    required ComputeSettlement computeSettlement,
    GetCycleSettlement? getCycleSettlement,
    required CloseSprint closeSprint,
    required CreateSprint createSprint,
  }) : _getHouseDetail = getHouseDetail,
       _getHouseInvite = getHouseInvite,
       _regenerateInviteCode = regenerateInviteCode,
       _removeMember = removeMember,
       _leaveHouse = leaveHouse,
       _getSprints = getSprints,
       _getSprintStats = getSprintStats,
       _computeSettlement = computeSettlement,
       _getCycleSettlement = getCycleSettlement,
       _closeSprint = closeSprint,
       _createSprint = createSprint,
       super(HouseDetailState(houseId: houseId)) {
    on<HouseDetailStarted>(_onStarted);
    on<HouseDetailRefreshRequested>(_onRefresh);
    on<HouseDetailRegenerateCodeRequested>(_onRegenerateCode);
    on<HouseDetailMemberRemoveRequested>(_onRemoveMember);
    on<HouseDetailLeaveRequested>(_onLeave);
    on<HouseDetailSprintSelected>(_onSprintSelected);
    on<HouseDetailEndSprintRequested>(_onEndSprint);
    on<HouseDetailConfirmCloseSprintRequested>(_onConfirmCloseSprint);
    on<HouseDetailCreateSprintRequested>(_onCreateSprint);
  }

  final GetHouseDetail _getHouseDetail;
  final GetHouseInvite _getHouseInvite;
  final RegenerateInviteCode _regenerateInviteCode;
  final RemoveMember _removeMember;
  final LeaveHouse _leaveHouse;
  final GetSprints _getSprints;
  final GetSprintStats _getSprintStats;
  final ComputeSettlement _computeSettlement;
  final GetCycleSettlement? _getCycleSettlement;
  final CloseSprint _closeSprint;
  final CreateSprint _createSprint;

  Future<void> _onStarted(
    HouseDetailStarted event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    HouseDetailRefreshRequested event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _onSprintSelected(
    HouseDetailSprintSelected event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(selectedSprint: event.sprint, clearSettlement: true));
    await _loadSprintStats(event.sprint, emit);
  }

  Future<void> _onEndSprint(
    HouseDetailEndSprintRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    final sprint = state.selectedSprint;
    if (sprint == null) return;

    emit(state.copyWith(isComputingSettlement: true, clearError: true));

    // If sprint is closed, check persisted settlement first
    if (!sprint.isOpen && _getCycleSettlement != null) {
      final persisted = await handleFutureRequest<Settlement?>(
        request: () => _getCycleSettlement(
          GetCycleSettlementParams(cycleId: sprint.id),
        ),
        debugger: ControllerDebugger(),
      );
      if (persisted != null) {
        emit(
          state.copyWith(
            isComputingSettlement: false,
            settlement: persisted,
          ),
        );
        return;
      }
    }

    final tapDate = DateTime.now();
    final settlement = await handleFutureRequest<Settlement>(
      request: () => _computeSettlement(
        ComputeSettlementParams(
          cycleId: sprint.id,
          calculationDate: tapDate,
          save: false,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            isComputingSettlement: false,
            errorMessage: failure.message,
          ),
        );
      },
    );

    emit(state.copyWith(isComputingSettlement: false, settlement: settlement));
  }

  Future<void> _onConfirmCloseSprint(
    HouseDetailConfirmCloseSprintRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));

    final tapDate = DateTime.now();

    // 1. Save settlement up to tap moment
    await handleFutureRequest<Settlement>(
      request: () => _computeSettlement(
        ComputeSettlementParams(
          cycleId: event.cycleId,
          calculationDate: tapDate,
          save: true,
        ),
      ),
      debugger: ControllerDebugger(),
    );

    // 2. Close sprint with effective closed/end date set to tap date
    await handleFutureRequest<Sprint>(
      request: () => _closeSprint(
        CloseSprintParams(cycleId: event.cycleId, closedAt: tapDate),
      ),
      debugger: ControllerDebugger(),
    );

    emit(state.copyWith(isActioning: false));
    await _load(emit);
  }

  Future<void> _onCreateSprint(
    HouseDetailCreateSprintRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));

    final sprint = await handleFutureRequest<Sprint>(
      request: () => _createSprint(
        CreateSprintParams(
          houseId: state.houseId,
          label: event.label,
          startDate: event.startDate,
          endDate: event.endDate,
        ),
      ),
      debugger: ControllerDebugger(),
    );

    emit(state.copyWith(isActioning: false));
    if (sprint != null) {
      await _load(emit);
    }
  }

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

    // 1. Fetch House Detail
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

    // 2. Fetch Invite
    final invite = await handleFutureRequest<HouseInvite>(
      request: () =>
          _getHouseInvite(GetHouseInviteParams(houseId: state.houseId)),
      debugger: ControllerDebugger(),
    );

    // 3. Fetch Sprints
    final sprints = await handleFutureRequest<List<Sprint>>(
      request: () => _getSprints(state.houseId),
      debugger: ControllerDebugger(),
    );

    final sprintList = sprints ?? [];
    // Prioritize open sprint or the latest sprint
    final runningSprint =
        sprintList.where((s) => s.isOpen).firstOrNull ??
        (sprintList.isNotEmpty ? sprintList.first : null);

    emit(
      state.copyWith(
        status: HouseDetailStatus.loaded,
        house: house,
        invite: invite,
        sprints: sprintList,
        selectedSprint: runningSprint,
        clearError: true,
      ),
    );

    if (runningSprint != null) {
      await _loadSprintStats(runningSprint, emit);
    }
  }

  Future<void> _loadSprintStats(
    Sprint sprint,
    Emitter<HouseDetailState> emit,
  ) async {
    final stats = await handleFutureRequest<Map<String, dynamic>>(
      request: () => _getSprintStats(
        GetSprintStatsParams(
          houseId: state.houseId,
          cycleId: sprint.id,
          startDate: sprint.startDate,
          endDate: sprint.endDate ?? DateTime.now(),
        ),
      ),
      debugger: ControllerDebugger(),
    );

    if (stats != null) {
      emit(state.copyWith(sprintStats: stats));
    }
  }
}
