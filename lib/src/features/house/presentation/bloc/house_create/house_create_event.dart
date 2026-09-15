part of 'house_create_bloc.dart';

sealed class HouseCreateEvent {}

final class HouseCreateNameChanged extends HouseCreateEvent {
  HouseCreateNameChanged(this.name);
  final String name;
}

final class HouseCreateSubmitted extends HouseCreateEvent {}
