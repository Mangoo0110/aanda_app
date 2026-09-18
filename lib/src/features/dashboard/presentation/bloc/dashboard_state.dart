part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, failure }

final class DashboardState {
  DashboardState({
    this.status = DashboardStatus.initial,
    this.summary,
    DateTime? selectedMonth,
    this.selectedHouseId,
    this.errorMessage,
  }) : selectedMonth =
           selectedMonth ?? DateTime(DateTime.now().year, DateTime.now().month);

  final DashboardStatus status;
  final DashboardSummary? summary;
  final DateTime selectedMonth;
  final String? selectedHouseId;
  final String? errorMessage;

  bool get isLoading => status == DashboardStatus.loading;

  double get personalSpent => summary?.personalSpent ?? 0.0;
  double get totalHouseSpent => summary?.totalHouseSpent ?? 0.0;
  double get myHouseContribution => summary?.myHouseContribution ?? 0.0;
  List<DashboardActivity> get activities => summary?.activities ?? const [];

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardSummary? summary,
    DateTime? selectedMonth,
    String? selectedHouseId,
    bool clearHouse = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      selectedMonth: selectedMonth ?? this.selectedMonth,
      selectedHouseId: clearHouse
          ? null
          : (selectedHouseId ?? this.selectedHouseId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
