part of 'house_join_bloc.dart';

sealed class HouseJoinEvent {}

final class HouseJoinCodeChanged extends HouseJoinEvent {
  HouseJoinCodeChanged(this.code);
  final String code;
}

final class HouseJoinSubmitted extends HouseJoinEvent {}
