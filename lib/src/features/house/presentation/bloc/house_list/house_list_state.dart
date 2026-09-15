part of 'house_list_bloc.dart';

enum HouseListStatus { initial, loading, loaded, failure }

final class HouseListState {
  const HouseListState({
    this.status = HouseListStatus.initial,
    this.houses = const [],
    this.errorMessage,
  });

  final HouseListStatus status;
  final List<House> houses;
  final String? errorMessage;

  bool get isLoading => status == HouseListStatus.loading;

  HouseListState copyWith({
    HouseListStatus? status,
    List<House>? houses,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseListState(
      status: status ?? this.status,
      houses: houses ?? this.houses,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
