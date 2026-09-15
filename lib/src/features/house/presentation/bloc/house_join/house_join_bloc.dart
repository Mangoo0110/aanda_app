import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_join_event.dart';
part 'house_join_state.dart';

final class HouseJoinBloc extends Bloc<HouseJoinEvent, HouseJoinState> {
  HouseJoinBloc({required JoinHouse joinHouse})
    : _joinHouse = joinHouse,
      super(const HouseJoinState()) {
    on<HouseJoinCodeChanged>(_onCodeChanged);
    on<HouseJoinSubmitted>(_onSubmitted);
  }

  final JoinHouse _joinHouse;

  void _onCodeChanged(
    HouseJoinCodeChanged event,
    Emitter<HouseJoinState> emit,
  ) {
    emit(state.copyWith(code: event.code, clearError: true));
  }

  Future<void> _onSubmitted(
    HouseJoinSubmitted event,
    Emitter<HouseJoinState> emit,
  ) async {
    final code = state.code.trim();
    if (code.length < 6) {
      emit(state.copyWith(errorMessage: 'Enter the full invite code.'));
      return;
    }

    emit(state.copyWith(status: HouseJoinStatus.submitting, clearError: true));

    final result = await handleFutureRequest<House>(
      request: () => _joinHouse(JoinHouseParams(inviteCode: code)),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseJoinStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      onSuccess: (house) {
        emit(
          state.copyWith(
            status: HouseJoinStatus.success,
            joinedHouseId: house.id,
            clearError: true,
          ),
        );
      },
    );

    if (result == null && state.status == HouseJoinStatus.submitting) {
      emit(state.copyWith(status: HouseJoinStatus.failure));
    }
  }
}
