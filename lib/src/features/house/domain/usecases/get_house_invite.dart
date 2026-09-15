import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house_invite.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class GetHouseInviteParams {
  const GetHouseInviteParams({required this.houseId});
  final String houseId;
}

final class GetHouseInvite
    implements AsyncUsecase<HouseInvite, GetHouseInviteParams> {
  const GetHouseInvite(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<HouseInvite> call(GetHouseInviteParams params) =>
      _repo.getHouseInvite(houseId: params.houseId);
}
