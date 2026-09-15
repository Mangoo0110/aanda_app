import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class JoinHouseParams {
  const JoinHouseParams({required this.inviteCode});
  final String inviteCode;
}

final class JoinHouse implements AsyncUsecase<House, JoinHouseParams> {
  const JoinHouse(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<House> call(JoinHouseParams params) =>
      _repo.joinHouse(inviteCode: params.inviteCode);
}
