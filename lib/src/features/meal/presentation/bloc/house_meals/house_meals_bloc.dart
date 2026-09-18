import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/entities/sprint.dart';
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
    required GetSprints getSprints,
  }) : _getHouseMembers = getHouseMembers,
       _getMealLogs = getMealLogs,
       _upsertMealLog = upsertMealLog,
       _getSprints = getSprints,
       super(
         HouseMealsState(
           houseId: houseId,
           cycleId: cycleId,
           selectedDate: DateTime.now(),
         ),
       ) {
    on<HouseMealsStarted>(_onStarted);
    on<HouseMealsRefreshRequested>(_onRefresh);
    on<HouseMealsDateSelected>(_onDateSelected);
    on<HouseMealEntryChanged>(_onMealEntryChanged);
    on<HouseMealsCycleChanged>(_onCycleChanged);
  }

  final GetHouseMembers _getHouseMembers;
  final GetMealLogs _getMealLogs;
  final UpsertMealLog _upsertMealLog;
  final GetSprints _getSprints;

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

  Future<void> _onCycleChanged(
    HouseMealsCycleChanged event,
    Emitter<HouseMealsState> emit,
  ) async {
    final sprint = event.sprint;
    emit(state.copyWith(
      cycleId: sprint.id,
      activeSprint: sprint,
      status: HouseMealsStatus.loading,
      mealLogs: [],
      clearError: true,
    ));

    final logs = await handleFutureRequest<List<MealLog>>(
      request: () => _getMealLogs(
        GetMealLogsParams(houseId: state.houseId, cycleId: sprint.id),
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
        mealLogs: logs,
        clearError: true,
      ));
    }
  }

  Future<void> _onMealEntryChanged(
    HouseMealEntryChanged event,
    Emitter<HouseMealsState> emit,
  ) async {
    // Preserve previous logs for rollback if saving fails
    final previousLogs = state.mealLogs;
    final updatedList = List<MealLog>.from(state.mealLogs);
    final dateStr = event.logDate.toIso8601String().substring(0, 10);
    final index = updatedList.indexWhere(
      (m) =>
          m.userId == event.userId &&
          m.logDate.toIso8601String().substring(0, 10) == dateStr,
    );

    final newLog = MealLog(
      id: index >= 0
          ? updatedList[index].id
          : 'temp-${DateTime.now().millisecondsSinceEpoch}',
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

    emit(state.copyWith(mealLogs: updatedList, isSaving: true, clearError: true));

    await handleFutureRequest<MealLog>(
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
        emit(
          state.copyWith(
            mealLogs: previousLogs,
            errorMessage: failure.message,
            isSaving: false,
          ),
        );
      },
      onSuccess: (data) {
        final refreshed = List<MealLog>.from(state.mealLogs);
        final savedIdx = refreshed.indexWhere(
          (m) =>
              m.userId == data.userId &&
              m.logDate.toIso8601String().substring(0, 10) == dateStr,
        );
        if (savedIdx >= 0) {
          refreshed[savedIdx] = data;
        } else {
          refreshed.add(data);
        }
        emit(
          state.copyWith(
            mealLogs: refreshed,
            isSaving: false,
            clearError: true,
          ),
        );
      },
    );
  }

  Future<void> _load(Emitter<HouseMealsState> emit) async {
    emit(state.copyWith(status: HouseMealsStatus.loading, clearError: true));

    // 1. Fetch sprints for cycle selector
    final sprints = await handleFutureRequest<List<Sprint>>(
      request: () => _getSprints(state.houseId),
      debugger: ControllerDebugger(),
    );

    // Determine the active sprint — prefer the one matching cycleId,
    // fall back to the most recent open one, then the most recent overall.
    Sprint? activeSprint;
    if (sprints != null && sprints.isNotEmpty) {
      activeSprint = sprints.where((s) => s.id == state.cycleId).firstOrNull ??
          sprints.where((s) => s.isOpen).lastOrNull ??
          sprints.last;
    }

    // 2. Fetch members
    final members = await handleFutureRequest<List<HouseMember>>(
      request: () => _getHouseMembers(state.houseId),
      debugger: ControllerDebugger(),
    );

    // 3. Fetch meal logs for the active cycle
    final effectiveCycleId = activeSprint?.id ?? state.cycleId;
    final logs = await handleFutureRequest<List<MealLog>>(
      request: () => _getMealLogs(
        GetMealLogsParams(houseId: state.houseId, cycleId: effectiveCycleId),
      ),
      debugger: ControllerDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            status: HouseMealsStatus.failure,
            errorMessage: failure.message,
          ),
        );
      },
    );

    if (logs != null) {
      emit(
        state.copyWith(
          status: HouseMealsStatus.loaded,
          members: members ?? state.members,
          mealLogs: logs,
          sprints: sprints ?? state.sprints,
          activeSprint: activeSprint,
          cycleId: effectiveCycleId,
          clearError: true,
        ),
      );
    } else {
      emit(state.copyWith(
        status: HouseMealsStatus.failure,
        sprints: sprints ?? state.sprints,
      ));
    }
  }
}

