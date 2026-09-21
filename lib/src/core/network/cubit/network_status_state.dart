class NetworkStatusState {
  const NetworkStatusState({
    required this.isOnline,
    required this.hasCheckedInitial,
    required this.isInitialOffline,
    required this.isMidSessionOffline,
    required this.wasOffline,
    required this.isChecking,
  });

  /// Whether device currently has internet reachability.
  final bool isOnline;

  /// Whether the initial connectivity check on app launch has completed.
  final bool hasCheckedInitial;

  /// True if the user opened the app without internet and hasn't connected yet.
  /// Used to display the full OfflineScreen on startup.
  final bool isInitialOffline;

  /// True if the app was previously online during this session, but lost connection suddenly.
  /// Used to display the floating "You are offline!" overlay banner.
  final bool isMidSessionOffline;

  /// True briefly when transitioning from offline -> online, allowing the overlay
  /// to show a green "Back online!" confirmation before dismissing.
  final bool wasOffline;

  /// True while a ping / check is actively in progress.
  final bool isChecking;

  factory NetworkStatusState.initial() => const NetworkStatusState(
        isOnline: true,
        hasCheckedInitial: false,
        isInitialOffline: false,
        isMidSessionOffline: false,
        wasOffline: false,
        isChecking: true,
      );

  NetworkStatusState copyWith({
    bool? isOnline,
    bool? hasCheckedInitial,
    bool? isInitialOffline,
    bool? isMidSessionOffline,
    bool? wasOffline,
    bool? isChecking,
  }) {
    return NetworkStatusState(
      isOnline: isOnline ?? this.isOnline,
      hasCheckedInitial: hasCheckedInitial ?? this.hasCheckedInitial,
      isInitialOffline: isInitialOffline ?? this.isInitialOffline,
      isMidSessionOffline: isMidSessionOffline ?? this.isMidSessionOffline,
      wasOffline: wasOffline ?? this.wasOffline,
      isChecking: isChecking ?? this.isChecking,
    );
  }
}
