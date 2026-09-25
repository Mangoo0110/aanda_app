import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';

part 'house_context_state.dart';

/// Global cubit that loads the user's house list once and provides the
/// currently selected house to all screens. Screens can call [selectHouse]
/// to switch context, eliminating repeated raw Supabase calls.
/// Persists the selected expense tracking account locally across app launches.
final class HouseContextCubit extends Cubit<HouseContextState> {
  HouseContextCubit({required GetMyHouses getMyHouses})
    : _getMyHouses = getMyHouses,
      super(const HouseContextState());

  final GetMyHouses _getMyHouses;
  static const String _prefKeySelectedAccount = 'selected_expense_account_id';

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
      final prefs = await SharedPreferences.getInstance();
      final savedAccountId = prefs.getString(_prefKeySelectedAccount);

      final personal = houses.where((h) => h.isPersonal).firstOrNull;
      final shared = houses.where((h) => h.isShared).toList();

      House? selected;
      bool isPersonal = true;

      if (savedAccountId != null && savedAccountId != 'personal') {
        final matchingShared =
            shared.where((h) => h.id == savedAccountId).firstOrNull;
        if (matchingShared != null) {
          selected = matchingShared;
          isPersonal = false;
        } else {
          selected = personal ?? shared.firstOrNull;
          isPersonal = selected?.isPersonal ?? true;
        }
      } else if (savedAccountId == 'personal') {
        selected = personal ?? shared.firstOrNull;
        isPersonal = true;
      } else {
        selected = personal ?? shared.firstOrNull;
        isPersonal = selected?.isPersonal ?? true;
      }

      emit(
        state.copyWith(
          status: HouseContextStatus.loaded,
          houses: houses,
          selectedHouse: selected,
          isPersonalView: isPersonal,
        ),
      );
    }
  }

  /// Refresh house list (e.g. after creating/joining a house).
  Future<void> refresh() async {
    emit(state.copyWith(status: HouseContextStatus.initial));
    await load();
  }

  /// Select a shared house — switches away from personal view and persists selection.
  void selectHouse(House house) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKeySelectedAccount, house.id);
    });
    emit(state.copyWith(selectedHouse: house, isPersonalView: false));
  }

  /// Switch to personal account view and persists selection.
  void selectPersonal() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKeySelectedAccount, 'personal');
    });
    emit(state.copyWith(
      selectedHouse: state.personalAccount,
      isPersonalView: true,
    ));
  }

  /// Notify that a new house was created/joined — prepend, select, and persist it.
  void onHouseJoined(House house) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(_prefKeySelectedAccount, house.id);
    });
    final updated = [house, ...state.houses.where((h) => h.id != house.id)];
    emit(state.copyWith(
      houses: updated,
      selectedHouse: house,
      isPersonalView: false,
    ));
  }

  /// Updates the avatar for a house and emits updated state immediately.
  void updateHouseAvatar(String houseId, String avatarUrl) {
    final updatedHouses = state.houses.map((h) {
      if (h.id == houseId) {
        return h.copyWith(avatarUrl: avatarUrl);
      }
      return h;
    }).toList();

    final updatedSelected = state.selectedHouse?.id == houseId
        ? state.selectedHouse?.copyWith(avatarUrl: avatarUrl)
        : state.selectedHouse;

    emit(state.copyWith(
      houses: updatedHouses,
      selectedHouse: updatedSelected,
    ));
  }

  /// Broadcasts that an expense was created, updated, or deleted.
  void notifyCostUpdated() {
    emit(state.copyWith(costUpdateCounter: state.costUpdateCounter + 1));
  }

  /// Broadcasts that meal records were logged or updated.
  void notifyMealUpdated() {
    emit(state.copyWith(mealUpdateCounter: state.mealUpdateCounter + 1));
  }
}
