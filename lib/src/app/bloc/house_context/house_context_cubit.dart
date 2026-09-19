import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_context_state.dart';

/// Global cubit that loads the user's house list once and provides the
/// currently selected house to all screens. Screens can call [selectHouse]
/// to switch context, eliminating repeated raw Supabase calls.
final class HouseContextCubit extends Cubit<HouseContextState> {
  HouseContextCubit({required GetMyHouses getMyHouses})
    : _getMyHouses = getMyHouses,
      super(const HouseContextState());

  final GetMyHouses _getMyHouses;

  /// Load houses from the repository. Called once after login.
  Future<void> load() async {
    if (state.status == HouseContextStatus.loading) return;
    emit(state.copyWith(status: HouseContextStatus.loading, clearError: true));

    final houses = await handleFutureRequest<List<House>>(
      request: () => _getMyHouses(const NoParams()),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseContextStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (houses != null) {
      final keepPersonal = state.isPersonalView;
      final personal = houses.where((h) => h.isPersonal).firstOrNull;
      final shared = houses.where((h) => h.isShared).toList();
      final selected = !keepPersonal &&
              state.selectedHouse != null &&
              shared.any((h) => h.id == state.selectedHouse!.id)
          ? state.selectedHouse
          : (!keepPersonal ? shared.firstOrNull : personal);
      emit(
        state.copyWith(
          status: HouseContextStatus.loaded,
          houses: houses,
          selectedHouse: selected,
          isPersonalView: keepPersonal,
        ),
      );
    }
  }

  /// Refresh house list (e.g. after creating/joining a house).
  Future<void> refresh() async {
    emit(state.copyWith(status: HouseContextStatus.initial));
    await load();
  }

  /// Select a shared house — switches away from personal view.
  void selectHouse(House house) {
    emit(state.copyWith(selectedHouse: house, isPersonalView: false));
  }

  /// Switch to personal account view.
  void selectPersonal() {
    emit(state.copyWith(
      selectedHouse: state.personalAccount,
      isPersonalView: true,
    ));
  }

  /// Notify that a new house was created/joined — prepend and select it.
  void onHouseJoined(House house) {
    final updated = [house, ...state.houses.where((h) => h.id != house.id)];
    emit(state.copyWith(houses: updated, selectedHouse: house));
  }
}
