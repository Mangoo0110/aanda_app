import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_list_event.dart';
part 'house_list_state.dart';

final class HouseListBloc extends Bloc<HouseListEvent, HouseListState> {
  HouseListBloc({required GetMyHouses getMyHouses})
    : _getMyHouses = getMyHouses,
      super(const HouseListState()) {
    on<HouseListStarted>(_onStarted);
    on<HouseListRefreshRequested>(_onRefresh);
  }

  final GetMyHouses _getMyHouses;

  Future<void> _onStarted(
    HouseListStarted event,
    Emitter<HouseListState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefresh(
    HouseListRefreshRequested event,
    Emitter<HouseListState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _load(Emitter<HouseListState> emit) async {
    emit(state.copyWith(status: HouseListStatus.loading, clearError: true));

    final result = await handleFutureRequest<List<House>>(
      request: () => _getMyHouses(const NoParams()),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseListStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
      onSuccess: (houses) {
        emit(
          state.copyWith(
            status: HouseListStatus.loaded,
            houses: houses,
            clearError: true,
          ),
        );
      },
    );

    if (result == null && state.status == HouseListStatus.loading) {
      emit(state.copyWith(status: HouseListStatus.failure));
    }
  }
}
