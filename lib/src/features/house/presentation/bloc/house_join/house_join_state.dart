part of 'house_join_bloc.dart';

enum HouseJoinStatus { initial, submitting, success, failure }

final class HouseJoinState {
  const HouseJoinState({
    this.code = '',
    this.status = HouseJoinStatus.initial,
    this.joinedHouseId,
    this.errorMessage,
  });

  final String code;
  final HouseJoinStatus status;
  final String? joinedHouseId;
  final String? errorMessage;

  bool get isSubmitting => status == HouseJoinStatus.submitting;

  HouseJoinState copyWith({
    String? code,
    HouseJoinStatus? status,
    String? joinedHouseId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseJoinState(
      code: code ?? this.code,
      status: status ?? this.status,
      joinedHouseId: joinedHouseId ?? this.joinedHouseId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
