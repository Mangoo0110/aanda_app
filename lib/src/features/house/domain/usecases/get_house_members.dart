import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house_member.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

final class GetHouseMembers implements AsyncUsecase<List<HouseMember>, String> {
  const GetHouseMembers(this._repo);

  final HouseRepo _repo;

  @override
  AsyncRequest<List<HouseMember>> call(String houseId) {
    return _repo.getHouseMembers(houseId: houseId);
  }
}
