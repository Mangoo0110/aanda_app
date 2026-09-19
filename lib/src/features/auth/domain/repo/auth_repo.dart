import '../../../../core/async_handlers/async_request.dart';
import '../entities/account.dart';
import '../entities/auth_credentials.dart';
import '../entities/auth_status.dart';

abstract interface class AuthRepo {
  Stream<AuthStatus> watchAuthStatus();

  AsyncRequest<AuthStatus> signInWithEmail({required SignInParams params});

  AsyncRequest<AuthStatus> signUpWithEmail({required SignUpParams params});

  AsyncRequest<AuthStatus> logout();

  AsyncRequest<Account?> getCurrentAccount();

  AsyncRequest<bool> isUsernameAvailable(String username);

  /// Archives the profile and deletes the auth user so login is impossible.
  AsyncRequest<void> deleteAccount();

  /// Resends signup confirmation email.
  AsyncRequest<void> resendEmailVerification({required String email});

  /// Sends a password reset email/OTP to [email].
  AsyncRequest<void> sendPasswordResetEmail({required String email});

  /// Verifies a recovery OTP code for [email].
  AsyncRequest<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  });

  /// Updates password to [newPassword] for current session.
  AsyncRequest<void> resetPassword({required String newPassword});
}
