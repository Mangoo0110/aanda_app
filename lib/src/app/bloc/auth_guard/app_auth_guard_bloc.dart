import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

part 'app_auth_guard_event.dart';

final class AppAuthGuardBloc extends Bloc<AppAuthGuardEvent, AuthStatus> {
  AppAuthGuardBloc({required WatchAuthStatus watchAuthStatus})
    : _watchAuthStatus = watchAuthStatus,
      super(LoadingAuthSignature()) {
    on<AppAuthGuardStarted>(_onStarted);
    on<_AppAuthGuardStatusChanged>(_onStatusChanged);
  }

  final WatchAuthStatus _watchAuthStatus;
  StreamSubscription<AuthStatus>? _authStatusSubscription;

  Future<void> _onStarted(
    AppAuthGuardStarted event,
    Emitter<AuthStatus> emit,
  ) async {
    await _authStatusSubscription?.cancel();
    _authStatusSubscription = _watchAuthStatus(
      const NoParams(),
    ).listen((status) => add(_AppAuthGuardStatusChanged(status)));
  }

  void _onStatusChanged(
    _AppAuthGuardStatusChanged event,
    Emitter<AuthStatus> emit,
  ) {
    emit(event.status);
  }

  @override
  Future<void> close() async {
    await _authStatusSubscription?.cancel();
    return super.close();
  }
}
