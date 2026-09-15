import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:aanda/src/features/auth/domain/entities/account.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_credentials.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

class AuthRepoImpl with ErrorHandler implements AuthRepo {
  AuthRepoImpl({required SupabaseAuthDatasource datasource})
    : _datasource = datasource;

  final SupabaseAuthDatasource _datasource;

  @override
  Stream<AuthStatus> watchAuthStatus() => _datasource.authStream;

  @override
  AsyncRequest<AuthStatus> signInWithEmail({required SignInParams params}) {
    return asyncTryCatch(
      tryFunc: () async {
        final account = await _datasource.signInWithEmail(params);
        return SuccessRepoCall(data: Authenticated(account));
      },
    );
  }

  @override
  AsyncRequest<AuthStatus> signUpWithEmail({required SignUpParams params}) {
    return asyncTryCatch(
      tryFunc: () async {
        final account = await _datasource.signUpWithEmail(params);
        return SuccessRepoCall(data: Authenticated(account));
      },
    );
  }

  @override
  AsyncRequest<AuthStatus> logout() {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.signOut();
        return const SuccessRepoCall(data: null);
      },
    );
  }

  @override
  AsyncRequest<Account?> getCurrentAccount() {
    return asyncTryCatch(
      tryFunc: () async {
        final account = await _datasource.getCurrentAccount();
        return SuccessRepoCall(data: account);
      },
    );
  }

  @override
  AsyncRequest<bool> isUsernameAvailable(String username) {
    return asyncTryCatch(
      tryFunc: () async {
        final available = await _datasource.isUsernameAvailable(username);
        return SuccessRepoCall(data: available);
      },
    );
  }
}
