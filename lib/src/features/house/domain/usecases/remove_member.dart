import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class RemoveMemberParams {
  const RemoveMemberParams({required this.houseId, required this.userId});
  final String houseId;
  final String userId;
}

final class RemoveMember implements AsyncUsecase<void, RemoveMemberParams> {
  const RemoveMember(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<void> call(RemoveMemberParams params) =>
      _repo.removeMember(houseId: params.houseId, userId: params.userId);
}
