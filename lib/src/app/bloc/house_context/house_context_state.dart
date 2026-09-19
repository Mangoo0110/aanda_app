part of 'house_context_cubit.dart';

enum HouseContextStatus { initial, loading, loaded, failure }

final class HouseContextState {
  const HouseContextState({
    this.status = HouseContextStatus.initial,
    this.houses = const [],
    this.selectedHouse,
    this.isPersonalView = true,
    this.errorMessage,
  });

  final HouseContextStatus status;
  final List<House> houses;
  final House? selectedHouse;
  /// True when the user has selected "My Personal Account" view.
  final bool isPersonalView;
  final String? errorMessage;

  bool get isLoading => status == HouseContextStatus.loading;
  bool get hasHouses => houses.isNotEmpty;

  /// The user's personal expense account (from DB)
  House? get personalAccount => houses.where((h) => h.isPersonal).firstOrNull;

  /// Shared houses / expense accounts (from DB)
  List<House> get sharedHouses => houses.where((h) => h.isShared).toList();

  /// Whether the user has joined any shared houses
  bool get hasSharedHouses => sharedHouses.isNotEmpty;

  /// Currently active account (either the personal account or selected shared house)
  House? get activeAccount => isPersonalView ? personalAccount : selectedHouse;

  /// ID of the currently active account
  String? get activeAccountId => activeAccount?.id;

  HouseContextState copyWith({
    HouseContextStatus? status,
    List<House>? houses,
    House? selectedHouse,
    bool clearSelectedHouse = false,
    bool? isPersonalView,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HouseContextState(
      status: status ?? this.status,
      houses: houses ?? this.houses,
      selectedHouse: clearSelectedHouse
          ? null
          : (selectedHouse ?? this.selectedHouse),
      isPersonalView: isPersonalView ?? this.isPersonalView,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
