import 'package:flutter_bloc/flutter_bloc.dart';
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
    final response = await _getHouseDetail(
      GetHouseDetailParams(houseId: state.houseId),
    );
    if (!response.success || response.data == null) {
      emit(
        state.copyWith(
          status: HouseDetailStatus.failure,
          errorMessage: response.message,
        ),
      );
      return;
    }

    final inviteResponse = await _getHouseInvite(
      GetHouseInviteParams(houseId: state.houseId),
    );

    emit(
      state.copyWith(
        status: HouseDetailStatus.loaded,
        house: response.data,
        invite: inviteResponse.data,
        clearError: true,
      ),
    );
  }

  Future<void> _onRegenerateCode(
    HouseDetailRegenerateCodeRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));
    final response = await _regenerateInviteCode(
      RegenerateInviteCodeParams(houseId: state.houseId),
    );
    if (!response.success) {
      emit(
        state.copyWith(isActioning: false, errorMessage: response.message),
      );
      return;
    }
    emit(state.copyWith(isActioning: false, invite: response.data));
  }

  Future<void> _onRemoveMember(
    HouseDetailMemberRemoveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));
    final response = await _removeMember(
      RemoveMemberParams(houseId: state.houseId, userId: event.userId),
    );
    if (!response.success) {
      emit(
        state.copyWith(isActioning: false, errorMessage: response.message),
      );
      return;
    }
    emit(state.copyWith(isActioning: false));
    await _load(emit);
  }

  Future<void> _onLeave(
    HouseDetailLeaveRequested event,
    Emitter<HouseDetailState> emit,
  ) async {
    emit(state.copyWith(isActioning: true, clearError: true));
    final response = await _leaveHouse(
      LeaveHouseParams(houseId: state.houseId),
    );
    if (!response.success) {
      emit(
        state.copyWith(isActioning: false, errorMessage: response.message),
      );
      return;
    }
    // Leaving is terminal — parent will pop this route.
    emit(state.copyWith(isActioning: false));
  }
}
