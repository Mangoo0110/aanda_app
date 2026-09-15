import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class LeaveHouseParams {
  const LeaveHouseParams({required this.houseId});
  final String houseId;
}

final class LeaveHouse implements AsyncUsecase<void, LeaveHouseParams> {
  const LeaveHouse(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<void> call(LeaveHouseParams params) =>
      _repo.leaveHouse(houseId: params.houseId);
}
