part of 'register_bloc.dart';

final class RegisterState {
  const RegisterState({
    this.email = '',
    this.fullName = '',
    this.password = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  final String email;
  final String fullName;
  final String password;
  final bool isSubmitting;
  final String? errorMessage;

  factory RegisterState.initial() => const RegisterState();

  RegisterState copyWith({
    String? email,
    String? fullName,
    String? password,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterState(
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
