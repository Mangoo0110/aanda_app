import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/usecases/house_usecases.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/domain/usecases/meal_usecases.dart';

part 'house_meals_event.dart';
part 'house_meals_state.dart';

final class HouseMealsBloc extends Bloc<HouseMealsEvent, HouseMealsState> {
  HouseMealsBloc({
    required String houseId,
    required String cycleId,
    required GetHouseMembers getHouseMembers,
    required GetMealLogs getMealLogs,
    required UpsertMealLog upsertMealLog,
  })  : _getHouseMembers = getHouseMembers,
        _getMealLogs = getMealLogs,
        _upsertMealLog = upsertMealLog,
        super(HouseMealsState(
          houseId: houseId,
          cycleId: cycleId,
          selectedDate: DateTime.now(),
        )) {
    on<HouseMealsStarted>(_onStarted);
    on<HouseMealsRefreshRequested>(_onRefresh);
    on<HouseMealsDateSelected>(_onDateSelected);
    on<HouseMealEntryChanged>(_onMealEntryChanged);
  }

  final GetHouseMembers _getHouseMembers;
  final GetMealLogs _getMealLogs;
  final UpsertMealLog _upsertMealLog;

  Future<void> _onStarted(
    HouseMealsStarted event,
    Emitter<HouseMealsState> emit,
  ) async {
    await _load(emit);
  }

  Future<void> _onRefresh(
    HouseMealsRefreshRequested event,
    Emitter<HouseMealsState> emit,
  ) async {
    await _load(emit);
  }

  void _onDateSelected(
    HouseMealsDateSelected event,
    Emitter<HouseMealsState> emit,
  ) {
    emit(state.copyWith(selectedDate: event.date));
  }

  Future<void> _onMealEntryChanged(
    HouseMealEntryChanged event,
    Emitter<HouseMealsState> emit,
  ) async {
    // Optimistic update
    final updatedList = List<MealLog>.from(state.mealLogs);
    final dateStr = event.logDate.toIso8601String().substring(0, 10);
    final index = updatedList.indexWhere((m) =>
        m.userId == event.userId &&
        m.logDate.toIso8601String().substring(0, 10) == dateStr);

    final newLog = MealLog(
      id: index >= 0 ? updatedList[index].id : 'temp-${DateTime.now().millisecondsSinceEpoch}',
      houseId: state.houseId,
      cycleId: state.cycleId,
      userId: event.userId,
      logDate: event.logDate,
      breakfast: event.breakfast,
      lunch: event.lunch,
      dinner: event.dinner,
    );

    if (index >= 0) {
      updatedList[index] = newLog;
    } else {
      updatedList.add(newLog);
    }

    emit(state.copyWith(mealLogs: updatedList, isSaving: true));

    final saved = await handleFutureRequest<MealLog>(
      request: () => _upsertMealLog(
        UpsertMealLogParams(
          houseId: state.houseId,
          cycleId: state.cycleId,
          userId: event.userId,
          logDate: event.logDate,
          breakfast: event.breakfast,
          lunch: event.lunch,
          dinner: event.dinner,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(
          errorMessage: failure.message,
          isSaving: false,
        ));
      },
      onSuccess: (data) {
        final refreshed = List<MealLog>.from(state.mealLogs);
        final savedIdx = refreshed.indexWhere((m) =>
            m.userId == data.userId &&
            m.logDate.toIso8601String().substring(0, 10) == dateStr);
        if (savedIdx >= 0) {
          refreshed[savedIdx] = data;
        } else {
          refreshed.add(data);
        }
        emit(state.copyWith(mealLogs: refreshed, isSaving: false));
      },
    );

    if (saved == null) {
      emit(state.copyWith(isSaving: false));
    }
  }

  Future<void> _load(Emitter<HouseMealsState> emit) async {
    emit(state.copyWith(status: HouseMealsStatus.loading, clearError: true));

    // 1. Fetch members
    final members = await handleFutureRequest<List<HouseMember>>(
      request: () => _getHouseMembers(state.houseId),
      debugger: ControllerDebugger(),
    );

    // 2. Fetch meal logs
    final logs = await handleFutureRequest<List<MealLog>>(
      request: () => _getMealLogs(
        GetMealLogsParams(
          houseId: state.houseId,
          cycleId: state.cycleId,
        ),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(state.copyWith(
          status: HouseMealsStatus.failure,
          errorMessage: failure.message,
        ));
      },
    );

    if (logs != null) {
      emit(state.copyWith(
        status: HouseMealsStatus.loaded,
        members: members ?? state.members,
        mealLogs: logs,
        clearError: true,
      ));
    } else {
      emit(state.copyWith(status: HouseMealsStatus.failure));
    }
  }
}
