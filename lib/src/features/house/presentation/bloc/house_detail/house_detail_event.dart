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

final class HouseDetailSprintSelected extends HouseDetailEvent {
  HouseDetailSprintSelected(this.sprint);
  final Sprint sprint;
}

final class HouseDetailEndSprintRequested extends HouseDetailEvent {}

final class HouseDetailConfirmCloseSprintRequested extends HouseDetailEvent {
  HouseDetailConfirmCloseSprintRequested(this.cycleId);
  final String cycleId;
}

final class HouseDetailCreateSprintRequested extends HouseDetailEvent {
  HouseDetailCreateSprintRequested({
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
}
