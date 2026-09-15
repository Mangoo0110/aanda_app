import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_detail_event.dart';
part 'house_detail_state.dart';

final class HouseDetailBloc
    extends Bloc<HouseDetailEvent, HouseDetailState> {
  HouseDetailBloc({
    required String houseId,
    required GetHouseDetail getHouseDetail,
    required GetHouseInvite getHouseInvite,
    required RegenerateInviteCode regenerateInviteCode,
    required RemoveMember removeMember,
    required LeaveHouse leaveHouse,
  }) : _getHouseDetail = getHouseDetail,
       _getHouseInvite = getHouseInvite,
       _regenerateInviteCode = regenerateInviteCode,
       _removeMember = removeMember,
       _leaveHouse = leaveHouse,
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

  Future<void> _onStarted(
    HouseDetailStarted event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _onRefresh(
    HouseDetailRefreshRequested event,
    Emitter<HouseDetailState> emit,
  ) async => _load(emit);

  Future<void> _load(Emitter<HouseDetailState> emit) async {
    emit(state.copyWith(status: HouseDetailStatus.loading, clearError: true));

    final house = await handleFutureRequest<House>(
      request: () => _getHouseDetail(
        GetHouseDetailParams(houseId: state.houseId),
      ),
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

    if (house == null) {
      if (state.status == HouseDetailStatus.loading) {
        emit(state.copyWith(status: HouseDetailStatus.failure));
      }
      return;
    }

    final invite = await handleFutureRequest<HouseInvite>(
      request: () => _getHouseInvite(
        GetHouseInviteParams(houseId: state.houseId),
      ),
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
        emit(
          state.copyWith(isActioning: false, errorMessage: failure.message),
        );
      },
      onSuccess: (invite) {
        emit(state.copyWith(isActioning: false, invite: invite));
      },
    );

    if (newInvite == null && state.isActioning) {
      emit(state.copyWith(isActioning: false));
    }
  }

  Future<void> _onRemoveMember(
    HouseDetailMemberRemoveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));

    bool isSuccess = false;
    await handleFutureRequest<void>(
      request: () => _removeMember(
        RemoveMemberParams(houseId: state.houseId, userId: event.userId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(isActioning: false, errorMessage: failure.message),
        );
      },
      onSuccess: (_) {
        isSuccess = true;
        emit(state.copyWith(isActioning: false));
      },
    );

    if (isSuccess) {
      await _load(emit);
    } else if (state.isActioning) {
      emit(state.copyWith(isActioning: false));
    }
  }

  Future<void> _onLeave(
    HouseDetailLeaveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));

    await handleFutureRequest<void>(
      request: () => _leaveHouse(
        LeaveHouseParams(houseId: state.houseId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(isActioning: false, errorMessage: failure.message),
        );
      },
      onSuccess: (_) {
        emit(state.copyWith(isActioning: false));
      },
    );

    if (state.isActioning) {
      emit(state.copyWith(isActioning: false));
    }
  }
}
