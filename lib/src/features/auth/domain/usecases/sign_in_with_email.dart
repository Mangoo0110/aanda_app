import '../../../../core/async_handlers/async_request.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/auth_credentials.dart';
import '../entities/auth_status.dart';
import '../repo/auth_repo.dart';

final class SignInWithEmail implements AsyncUsecase<AuthStatus, SignInParams> {
  const SignInWithEmail(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<AuthStatus> call(SignInParams params) {
    return _repo.signInWithEmail(params: params);
  }
}
