import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/entities/auth_status.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

final class WatchAuthStatus implements StreamUsecase<AuthStatus, NoParams> {
  const WatchAuthStatus(this._repo);

  final AuthRepo _repo;

  @override
  Stream<AuthStatus> call(NoParams params) {
    return _repo.watchAuthStatus();
  }
}
