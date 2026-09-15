import '../../../../core/async_handlers/async_request.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/auth_credentials.dart';
import '../entities/auth_status.dart';
import '../repo/auth_repo.dart';

final class SignUpWithEmail implements AsyncUsecase<AuthStatus, SignUpParams> {
  const SignUpWithEmail(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<AuthStatus> call(SignUpParams params) {
    return _repo.signUpWithEmail(params: params);
  }
}
