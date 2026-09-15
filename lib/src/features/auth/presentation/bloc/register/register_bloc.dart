import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:aanda/src/features/auth/domain/usecases/auth_usecases.dart';

part 'register_event.dart';
part 'register_state.dart';

final class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({required SignUpWithEmail signUpWithEmail})
    : _signUpWithEmail = signUpWithEmail,
      super(RegisterState.initial()) {
    on<RegisterEmailChanged>(_onEmailChanged);
    on<RegisterFullNameChanged>(_onFullNameChanged);
    on<RegisterPasswordChanged>(_onPasswordChanged);
    on<RegisterSubmitted>(_onSubmitted);
  }

  final SignUpWithEmail _signUpWithEmail;

  void _onEmailChanged(RegisterEmailChanged event, Emitter<RegisterState> emit) {
    emit(state.copyWith(email: event.email, clearError: true));
  }

  void _onFullNameChanged(
    RegisterFullNameChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(fullName: event.fullName, clearError: true));
  }

  void _onPasswordChanged(
    RegisterPasswordChanged event,
    Emitter<RegisterState> emit,
  ) {
    emit(state.copyWith(password: event.password, clearError: true));
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
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
    final response = await _signUpWithEmail(
      SignUpParams(
        email: email,
        password: password,
        fullName: state.fullName.trim().isEmpty ? null : state.fullName.trim(),
      ),
    );

    if (!response.success || response.data == null) {
      emit(
        state.copyWith(isSubmitting: false, errorMessage: response.message),
      );
      return;
    }

    // On success the Supabase auth stream will emit Authenticated → router redirects.
    emit(state.copyWith(isSubmitting: false, clearError: true));
  }
}
