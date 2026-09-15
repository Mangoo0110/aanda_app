import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/core/utils/debug/debug_service.dart';
import 'package:aanda/src/core/utils/helpers/handle_future_request.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

part 'login_event.dart';
part 'login_state.dart';

final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required SignInWithEmail signInWithEmail})
    : _signInWithEmail = signInWithEmail,
      super(LoginState.initial()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  final SignInWithEmail _signInWithEmail;

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    emit(state.copyWith(email: event.email, clearError: true));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(password: event.password, clearError: true));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final email = state.email.trim();
    final password = state.password;

    if (email.isEmpty || !email.contains('@')) {
      emit(state.copyWith(errorMessage: 'Enter a valid email address.'));
      return;
    }
    if (password.length < 6) {
      emit(
        state.copyWith(errorMessage: 'Password must be at least 6 characters.'),
      );
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true));

    final result = await handleFutureRequest<AuthStatus>(
      request: () => _signInWithEmail(
        SignInParams(email: email, password: password),
      ),
      debugger: AuthDebugger(),
      onError: (failure) {
        emit(
          state.copyWith(
            isSubmitting: false,
            errorMessage: failure.message,
          ),
        );
      },
      onSuccess: (status) {
        emit(state.copyWith(isSubmitting: false, clearError: true));
      },
    );

    if (result == null && state.isSubmitting) {
      emit(state.copyWith(isSubmitting: false));
    }
  }
}
