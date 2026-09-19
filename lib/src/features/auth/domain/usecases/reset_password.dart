import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class ResetPassword implements AsyncUsecase<void, String> {
  const ResetPassword(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<void> call(String newPassword) =>
      _repo.resetPassword(newPassword: newPassword);
}
