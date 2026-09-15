import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class Logout implements AsyncUsecase<AuthStatus, NoParams> {
  const Logout(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<AuthStatus> call(NoParams params) {
    return _repo.logout();
  }
}
