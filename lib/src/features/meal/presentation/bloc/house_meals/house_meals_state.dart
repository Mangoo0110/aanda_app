part of 'house_meals_bloc.dart';

enum HouseMealsStatus { initial, loading, loaded, failure }

final class HouseMealsState {
  const HouseMealsState({
    this.status = HouseMealsStatus.initial,
    this.houseId = '',
    this.cycleId = '',
    this.members = const [],
    this.mealLogs = const [],
    required this.selectedDate,
    this.errorMessage,
    this.isSaving = false,
  });

  final HouseMealsStatus status;
  final String houseId;
  final String cycleId;
  final List<HouseMember> members;
  final List<MealLog> mealLogs;
  final DateTime selectedDate;
  final String? errorMessage;
  final bool isSaving;

  bool get isLoading => status == HouseMealsStatus.loading;

  /// Returns meal log for specific user and date
  MealLog? mealFor(String userId, DateTime date) {
    final dateStr = date.toIso8601String().substring(0, 10);
    return mealLogs.where((m) {
      final mDateStr = m.logDate.toIso8601String().substring(0, 10);
      return m.userId == userId && mDateStr == dateStr;
    }).firstOrNull;
  }

  /// Total meals recorded in this sprint
  double get totalSprintMeals {
    return mealLogs.fold<double>(0.0, (sum, m) => sum + m.totalMeals);
  }

  /// Total meals recorded for the selected date
  double get totalMealsForSelectedDate {
    final dateStr = selectedDate.toIso8601String().substring(0, 10);
    return mealLogs.where((m) {
      return m.logDate.toIso8601String().substring(0, 10) == dateStr;
    }).fold<double>(0.0, (sum, m) => sum + m.totalMeals);
  }

  HouseMealsState copyWith({
    HouseMealsStatus? status,
    String? houseId,
    String? cycleId,
    List<HouseMember>? members,
    List<MealLog>? mealLogs,
    DateTime? selectedDate,
    String? errorMessage,
    bool clearError = false,
    bool? isSaving,
  }) {
    return HouseMealsState(
      status: status ?? this.status,
      houseId: houseId ?? this.houseId,
      cycleId: cycleId ?? this.cycleId,
      members: members ?? this.members,
      mealLogs: mealLogs ?? this.mealLogs,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
