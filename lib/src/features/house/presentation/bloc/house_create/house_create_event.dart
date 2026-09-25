part of 'house_create_bloc.dart';

sealed class HouseCreateEvent {
  const HouseCreateEvent();
}

final class HouseCreateNameChanged extends HouseCreateEvent {
  const HouseCreateNameChanged(this.name);
  final String name;
}

final class HouseCreateSubmitted extends HouseCreateEvent {
  const HouseCreateSubmitted({
    this.avatarBytes,
    this.avatarExtension,
  });

  final List<int>? avatarBytes;
  final String? avatarExtension;
}
