import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/network/cubit/network_status_state.dart';

class NetworkStatusCubit extends Cubit<NetworkStatusState> {
  NetworkStatusCubit({Duration checkInterval = const Duration(seconds: 6)})
      : _checkInterval = checkInterval,
        super(NetworkStatusState.initial()) {
    _init();
  }

  final Duration _checkInterval;
  Timer? _periodicTimer;
  Timer? _wasOfflineDismissTimer;
  bool _isCheckingInternal = false;

  void _init() {
    // 1. Initial check immediately on launch
    checkConnectivity(isInitial: true);

    // 2. Periodic background reachability ping
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      if (!_isCheckingInternal) {
        checkConnectivity(isInitial: false);
      }
    });
  }

  Future<void> checkConnectivity({bool isInitial = false}) async {
    if (_isCheckingInternal) return;
    _isCheckingInternal = true;

    emit(state.copyWith(isChecking: true));

    final reachable = await _pingInternet();

    _isCheckingInternal = false;

    final wasOnlineBefore = state.isOnline;
    final hadCheckedInitial = state.hasCheckedInitial;

    if (!hadCheckedInitial || isInitial) {
      // App just opened:
      // If offline on startup, mark as isInitialOffline (shows full OfflineScreen)
      emit(state.copyWith(
        isOnline: reachable,
        hasCheckedInitial: true,
        isInitialOffline: !reachable,
        isMidSessionOffline: false,
        wasOffline: false,
        isChecking: false,
      ));
      return;
    }

    // Mid-session update:
    if (!reachable) {
      // Went offline mid-session!
      _wasOfflineDismissTimer?.cancel();
      emit(state.copyWith(
        isOnline: false,
        // If it was already in initial offline screen, keep it there until restored.
        // Otherwise, flag mid-session offline overlay.
        isMidSessionOffline: !state.isInitialOffline,
        wasOffline: false,
        isChecking: false,
      ));
    } else {
      // We are online!
      final justReconnected = !wasOnlineBefore;

      emit(state.copyWith(
        isOnline: true,
        isInitialOffline: false,
        isMidSessionOffline: false,
        wasOffline: justReconnected,
        isChecking: false,
      ));

      if (justReconnected) {
        // Auto-dismiss the "Back online" toast after 2.5 seconds
        _wasOfflineDismissTimer?.cancel();
        _wasOfflineDismissTimer = Timer(const Duration(milliseconds: 2500), () {
          if (!isClosed) {
            emit(state.copyWith(wasOffline: false));
          }
        });
      }
    }
  }

  /// Ping real DNS / hosts to verify actual internet connectivity
  Future<bool> _pingInternet() async {
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('1.1.1.1')
            .timeout(const Duration(seconds: 3));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  /// Manually force a retry (e.g. from Retry button)
  Future<void> retry() => checkConnectivity(isInitial: state.isInitialOffline);

  @override
  Future<void> close() {
    _periodicTimer?.cancel();
    _wasOfflineDismissTimer?.cancel();
    return super.close();
  }
}
