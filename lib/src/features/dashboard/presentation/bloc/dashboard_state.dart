part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, failure }

final class DashboardState {
  DashboardState({
    this.status = DashboardStatus.initial,
    this.summary,
    DateTime? selectedMonth,
    this.selectedHouseId,
    this.cycles = const [],
    this.selectedCycle,
    this.errorMessage,
    this.todayMealLogs = const [],
    this.houseMembers = const [],
    this.isTodayMealsLoading = false,
    this.recentCosts = const [],
  }) : selectedMonth =
           selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  final DashboardStatus status;
  final DashboardSummary? summary;
  final DateTime selectedMonth;
  final String? selectedHouseId;
  final List<Sprint> cycles;
  final Sprint? selectedCycle;
  final String? errorMessage;
  final List<MealLog> todayMealLogs;
  final List<HouseMember> houseMembers;
  final bool isTodayMealsLoading;
  final List<Cost> recentCosts;

  bool get isLoading => status == DashboardStatus.loading;

  double get personalSpent => summary?.personalSpent ?? 0.0;
  double get totalHouseSpent => summary?.totalHouseSpent ?? 0.0;
  double get myHouseContribution => summary?.myHouseContribution ?? 0.0;
  double get myTotalSpent => myHouseContribution + personalSpent;
  List<DashboardActivity> get activities => summary?.activities ?? const [];
  List<Cost> get effectiveRecentCosts =>
      recentCosts.isNotEmpty ? recentCosts : (summary?.recentCosts ?? const []);

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    DateTime? selectedMonth,
    String? selectedHouseId,
    bool clearHouse = false,
    List<Sprint>? cycles,
    Sprint? selectedCycle,
    bool clearCycle = false,
    String? errorMessage,
    bool clearError = false,
    List<MealLog>? todayMealLogs,
    List<HouseMember>? houseMembers,
    bool? isTodayMealsLoading,
    List<Cost>? recentCosts,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedHouseId: clearHouse
          ? null
          : (selectedHouseId ?? this.selectedHouseId),
      cycles: cycles ?? this.cycles,
      selectedCycle: clearCycle
          ? null
          : (selectedCycle ?? this.selectedCycle),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      todayMealLogs: todayMealLogs ?? this.todayMealLogs,
      houseMembers: houseMembers ?? this.houseMembers,
      isTodayMealsLoading: isTodayMealsLoading ?? this.isTodayMealsLoading,
      recentCosts: recentCosts ?? this.recentCosts,
    );
  }
}
