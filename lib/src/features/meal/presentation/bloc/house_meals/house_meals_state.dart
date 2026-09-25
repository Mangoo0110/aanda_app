part of 'house_meals_bloc.dart';

enum HouseMealsStatus { initial, loading, loaded, failure }

final class HouseMealsState {
  const HouseMealsState({
    this.status = HouseMealsStatus.initial,
    this.houseId = '',
    this.cycleId = '',
    this.members = const [],
    this.mealLogs = const [],
    this.sprints = const [],
    this.activeSprint,
    required this.selectedDate,
    this.selectedMemberUserId,
    this.errorMessage,
    this.isSaving = false,
  });

  final HouseMealsStatus status;
  final String houseId;
  final String cycleId;
  final List<HouseMember> members;
  final List<MealLog> mealLogs;
  final List<Sprint> sprints;
  final Sprint? activeSprint;
  final DateTime selectedDate;
  final String? selectedMemberUserId;
  final String? errorMessage;
  final bool isSaving;

  bool get isLoading => status == HouseMealsStatus.loading;

  /// Returns the currently active selected member
  HouseMember selectedMember(String? fallbackUserId) {
    if (members.isEmpty) {
      return HouseMember(
        id: '',
        houseId: houseId,
        userId: fallbackUserId ?? '',
        role: MemberRole.member,
        joinedAt: DateTime.now(),
        fullName: 'Member',
      );
    }
    final targetId = selectedMemberUserId ?? fallbackUserId;
    return members.where((m) => m.userId == targetId).firstOrNull ?? members.first;
  }

  /// Total meals recorded for a specific user
  double memberTotalMeals(String userId) {
    return mealLogs
        .where((m) => m.userId == userId)
        .fold<double>(0.0, (sum, m) => sum + m.totalMeals);
  }

  /// Ordered list of days in the active sprint cycle (newest to oldest)
  List<DateTime> get sprintDays {
    final now = DateTime.now();
    final sprintStart = activeSprint != null
        ? DateTime(activeSprint!.startDate.year, activeSprint!.startDate.month, activeSprint!.startDate.day)
        : DateTime(now.year, now.month, 1);
    final sprintEnd = activeSprint != null
        ? (activeSprint!.endDate != null
            ? DateTime(activeSprint!.endDate!.year, activeSprint!.endDate!.month, activeSprint!.endDate!.day)
            : DateTime(now.year, now.month, now.day))
        : DateTime(now.year, now.month + 1, 0);

    final List<DateTime> days = [];
    var currDate = sprintEnd;
    while (!currDate.isBefore(sprintStart)) {
      days.add(currDate);
      currDate = currDate.subtract(const Duration(days: 1));
    }
    return days;
  }

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
    return mealLogs
        .where((m) => m.logDate.toIso8601String().substring(0, 10) == dateStr)
        .fold<double>(0.0, (sum, m) => sum + m.totalMeals);
  }

  HouseMealsState copyWith({
    HouseMealsStatus? status,
    String? houseId,
    String? cycleId,
    List<HouseMember>? members,
    List<MealLog>? mealLogs,
    List<Sprint>? sprints,
    Sprint? activeSprint,
    bool clearActiveSprint = false,
    DateTime? selectedDate,
    String? selectedMemberUserId,
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
      sprints: sprints ?? this.sprints,
      activeSprint: clearActiveSprint ? null : (activeSprint ?? this.activeSprint),
      selectedDate: selectedDate ?? this.selectedDate,
      selectedMemberUserId: selectedMemberUserId ?? this.selectedMemberUserId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSaving: isSaving ?? this.isSaving,
    );
  }
}
