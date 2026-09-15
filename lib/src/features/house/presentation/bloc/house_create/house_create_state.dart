part of 'house_create_bloc.dart';

enum HouseCreateStatus { initial, submitting, success, failure }

final class HouseCreateState {
  const HouseCreateState({
    this.name = '',
    this.status = HouseCreateStatus.initial,
    this.createdHouseId,
    this.errorMessage,
  });

  final String name;
  final HouseCreateStatus status;
  final String? createdHouseId;
  final String? errorMessage;

  bool get isSubmitting => status == HouseCreateStatus.submitting;

  HouseCreateState copyWith({
    String? name,
    HouseCreateStatus? status,
    String? createdHouseId,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseCreateState(
      name: name ?? this.name,
      status: status ?? this.status,
      createdHouseId: createdHouseId ?? this.createdHouseId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
