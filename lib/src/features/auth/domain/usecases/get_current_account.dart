import '../../../../core/async_handlers/async_request.dart';
import '../../../../core/usecases/base_usecase.dart';
import '../entities/account.dart';
import '../repo/auth_repo.dart';

final class GetCurrentAccount implements AsyncUsecase<Account?, NoParams> {
  const GetCurrentAccount(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<Account?> call(NoParams params) {
    return _repo.getCurrentAccount();
  }
}
