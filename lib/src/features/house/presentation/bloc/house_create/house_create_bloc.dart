import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_create_event.dart';
part 'house_create_state.dart';

final class HouseCreateBloc
    extends Bloc<HouseCreateEvent, HouseCreateState> {
  HouseCreateBloc({required CreateHouse createHouse})
    : _createHouse = createHouse,
      super(const HouseCreateState()) {
    on<HouseCreateNameChanged>(_onNameChanged);
    on<HouseCreateSubmitted>(_onSubmitted);
  }

  final CreateHouse _createHouse;

  void _onNameChanged(
    HouseCreateNameChanged event,
    Emitter<HouseCreateState> emit,
  ) {
    emit(state.copyWith(name: event.name, clearError: true));
  }

  Future<void> _onSubmitted(
    HouseCreateSubmitted event,
    Emitter<HouseCreateState> emit,
  ) async {
    final name = state.name.trim();
    if (name.length < 2) {
      emit(state.copyWith(errorMessage: 'House name must be at least 2 characters.'));
      return;
    }

    emit(state.copyWith(status: HouseCreateStatus.submitting, clearError: true));
    final response = await _createHouse(CreateHouseParams(name: name));

    if (!response.success || response.data == null) {
      emit(
        state.copyWith(
          status: HouseCreateStatus.failure,
          errorMessage: response.message,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: HouseCreateStatus.success,
        createdHouseId: response.data!.id,
        clearError: true,
      ),
    );
  }
}
