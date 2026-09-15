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
}
