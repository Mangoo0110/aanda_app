import 'package:flutter_bloc/flutter_bloc.dart';
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
    final response = await _joinHouse(JoinHouseParams(inviteCode: code));

    if (!response.success || response.data == null) {
      emit(
        state.copyWith(
          status: HouseJoinStatus.failure,
          errorMessage: response.message,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: HouseJoinStatus.success,
        joinedHouseId: response.data!.id,
        clearError: true,
      ),
    );
  }
}
