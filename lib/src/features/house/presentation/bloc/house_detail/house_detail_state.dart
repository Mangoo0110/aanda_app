part of 'house_detail_bloc.dart';

enum HouseDetailStatus { initial, loading, loaded, failure }

final class HouseDetailState {
  const HouseDetailState({
    required this.houseId,
    this.status = HouseDetailStatus.initial,
    this.house,
    this.invite,
    this.isActioning = false,
    this.errorMessage,
  });

  final String houseId;
  final HouseDetailStatus status;
  final House? house;
  final HouseInvite? invite;
  final bool isActioning;
  final String? errorMessage;

  bool get isLoading => status == HouseDetailStatus.loading;

  HouseDetailState copyWith({
    HouseDetailStatus? status,
    House? house,
    HouseInvite? invite,
    bool? isActioning,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseDetailState(
      houseId: houseId,
      status: status ?? this.status,
      house: house ?? this.house,
      invite: invite ?? this.invite,
      isActioning: isActioning ?? this.isActioning,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
