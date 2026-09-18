part of 'house_detail_bloc.dart';

enum HouseDetailStatus { initial, loading, loaded, failure }

final class HouseDetailState {
  const HouseDetailState({
    required this.houseId,
    this.status = HouseDetailStatus.initial,
    this.house,
    this.invite,
    this.sprints = const [],
    this.selectedSprint,
    this.sprintStats,
    this.settlement,
    this.isActioning = false,
    this.isComputingSettlement = false,
    this.errorMessage,
  });

  final String houseId;
  final HouseDetailStatus status;
  final House? house;
  final HouseInvite? invite;
  final List<Sprint> sprints;
  final Sprint? selectedSprint;
  final Map<String, dynamic>? sprintStats;
  final Settlement? settlement;
  final bool isActioning;
  final bool isComputingSettlement;
  final String? errorMessage;

  bool get isLoading => status == HouseDetailStatus.loading;

  double get sprintTotalSpent =>
      (sprintStats?['totalSpent'] as num?)?.toDouble() ?? 0.0;
  double get sprintMyContribution =>
      (sprintStats?['myContribution'] as num?)?.toDouble() ?? 0.0;
  double get sprintFoodSpent =>
      (sprintStats?['foodSpent'] as num?)?.toDouble() ?? 0.0;
  double get sprintTotalMeals =>
      (sprintStats?['totalMeals'] as num?)?.toDouble() ?? 0.0;
  double get sprintMyMeals =>
      (sprintStats?['myMeals'] as num?)?.toDouble() ?? 0.0;
  double get sprintEstimatedMealRate =>
      (sprintStats?['estimatedMealRate'] as num?)?.toDouble() ?? 0.0;

  HouseDetailState copyWith({
    HouseDetailStatus? status,
    House? house,
    HouseInvite? invite,
    List<Sprint>? sprints,
    Sprint? selectedSprint,
    Map<String, dynamic>? sprintStats,
    Settlement? settlement,
    bool clearSettlement = false,
    bool? isActioning,
    bool? isComputingSettlement,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseDetailState(
      houseId: houseId,
      status: status ?? this.status,
      house: house ?? this.house,
      invite: invite ?? this.invite,
      sprints: sprints ?? this.sprints,
      selectedSprint: selectedSprint ?? this.selectedSprint,
      sprintStats: sprintStats ?? this.sprintStats,
      settlement: clearSettlement ? null : (settlement ?? this.settlement),
      isActioning: isActioning ?? this.isActioning,
      isComputingSettlement:
          isComputingSettlement ?? this.isComputingSettlement,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
