part of 'house_detail_bloc.dart';

enum HouseDetailStatus { initial, loading, loaded, failure }

final class HouseDetailState {
  const HouseDetailState({
    required this.houseId,
    this.status = HouseDetailStatus.initial,
    this.house,
    this.invite,
    this.accountStats,
    this.isActioning = false,
    this.errorMessage,
  });

  final String houseId;
  final HouseDetailStatus status;
  final House? house;
  final HouseInvite? invite;
  final Map<String, dynamic>? accountStats;
  final bool isActioning;
  final String? errorMessage;

  bool get isLoading => status == HouseDetailStatus.loading;

  double get totalSpent =>
      (accountStats?['totalSpent'] as num?)?.toDouble() ?? 0.0;
  double get myContribution =>
      (accountStats?['myContribution'] as num?)?.toDouble() ?? 0.0;
  double get foodSpent =>
      (accountStats?['foodSpent'] as num?)?.toDouble() ?? 0.0;
  double get totalMeals =>
      (accountStats?['totalMeals'] as num?)?.toDouble() ?? 0.0;
  double get myMeals =>
      (accountStats?['myMeals'] as num?)?.toDouble() ?? 0.0;
  double get estimatedMealRate =>
      (accountStats?['estimatedMealRate'] as num?)?.toDouble() ?? 0.0;

  HouseDetailState copyWith({
    HouseDetailStatus? status,
    House? house,
    HouseInvite? invite,
    Map<String, dynamic>? accountStats,
    bool? isActioning,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseDetailState(
      houseId: houseId,
      status: status ?? this.status,
      house: house ?? this.house,
      invite: invite ?? this.invite,
      accountStats: accountStats ?? this.accountStats,
      isActioning: isActioning ?? this.isActioning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
