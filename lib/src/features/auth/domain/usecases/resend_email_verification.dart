import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class ResendEmailVerification implements AsyncUsecase<void, String> {
  const ResendEmailVerification(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<void> call(String email) =>
      _repo.resendEmailVerification(email: email);
}
