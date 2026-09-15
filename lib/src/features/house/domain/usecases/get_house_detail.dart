import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class GetHouseDetailParams {
  const GetHouseDetailParams({required this.houseId});
  final String houseId;
}

final class GetHouseDetail
    implements AsyncUsecase<House, GetHouseDetailParams> {
  const GetHouseDetail(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<House> call(GetHouseDetailParams params) =>
      _repo.getHouseDetail(houseId: params.houseId);
}
