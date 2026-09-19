part of 'register_bloc.dart';

final class RegisterState {
  const RegisterState({
    this.email = '',
    this.fullName = '',
    this.password = '',
    this.isSubmitting = false,
    this.needsEmailConfirmation = false,
    this.isResendingEmail = false,
    this.resendSuccessMessage,
    this.errorMessage,
  });

  final String email;
  final String fullName;
  final String password;
  final bool isSubmitting;
  final bool needsEmailConfirmation;
  final bool isResendingEmail;
  final String? resendSuccessMessage;
  final String? errorMessage;

  factory RegisterState.initial() => const RegisterState();

  RegisterState copyWith({
    String? email,
    String? fullName,
    String? password,
    bool? isSubmitting,
    bool? needsEmailConfirmation,
    bool? isResendingEmail,
    String? resendSuccessMessage,
    bool clearResendMessage = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RegisterState(
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      needsEmailConfirmation:
          needsEmailConfirmation ?? this.needsEmailConfirmation,
      isResendingEmail: isResendingEmail ?? this.isResendingEmail,
      resendSuccessMessage: clearResendMessage
          ? null
          : (resendSuccessMessage ?? this.resendSuccessMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
