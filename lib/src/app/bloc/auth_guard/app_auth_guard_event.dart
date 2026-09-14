part of 'app_auth_guard_bloc.dart';

sealed class AppAuthGuardEvent {
  const AppAuthGuardEvent();
}

final class AppAuthGuardStarted extends AppAuthGuardEvent {
  const AppAuthGuardStarted();
}

final class _AppAuthGuardStatusChanged extends AppAuthGuardEvent {
  const _AppAuthGuardStatusChanged(this.status);

  final AuthStatus status;
}
