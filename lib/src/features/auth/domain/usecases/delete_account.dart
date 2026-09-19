import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/auth/domain/repo/auth_repo.dart';

/// Permanently deactivates the current user's account.
///
/// Under the hood this archives the profile row and deletes the Supabase
/// auth entry so the user can never log back in.  Historical shared-house
/// data (costs, meals, settlements) is preserved for other members.
final class DeleteAccount implements AsyncUsecase<void, NoParams> {
  const DeleteAccount(this._repo);

  final AuthRepo _repo;

  @override
  AsyncRequest<void> call(NoParams params) => _repo.deleteAccount();
}
