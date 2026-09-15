import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class RegenerateInviteCodeParams {
  const RegenerateInviteCodeParams({required this.houseId});
  final String houseId;
}

final class RegenerateInviteCode
    implements AsyncUsecase<HouseInvite, RegenerateInviteCodeParams> {
  const RegenerateInviteCode(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<HouseInvite> call(RegenerateInviteCodeParams params) =>
      _repo.regenerateInviteCode(houseId: params.houseId);
}
