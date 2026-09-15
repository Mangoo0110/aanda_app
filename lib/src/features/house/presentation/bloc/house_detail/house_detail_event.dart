part of 'house_detail_bloc.dart';

sealed class HouseDetailEvent {}

final class HouseDetailStarted extends HouseDetailEvent {}

final class HouseDetailRefreshRequested extends HouseDetailEvent {}

final class HouseDetailRegenerateCodeRequested extends HouseDetailEvent {}

final class HouseDetailMemberRemoveRequested extends HouseDetailEvent {
  HouseDetailMemberRemoveRequested(this.userId);
  final String userId;
}

final class HouseDetailLeaveRequested extends HouseDetailEvent {}
