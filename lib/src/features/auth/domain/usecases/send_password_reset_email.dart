import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class SendPasswordResetEmail implements AsyncUsecase<void, String> {
  const SendPasswordResetEmail(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<void> call(String email) =>
      _repo.sendPasswordResetEmail(email: email);
}
