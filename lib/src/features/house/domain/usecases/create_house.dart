import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/house/domain/entities/house.dart';
import 'package:aanda/src/features/house/domain/repo/house_repo.dart';

class CreateHouseParams {
  const CreateHouseParams({required this.name});
  final String name;
}

final class CreateHouse implements AsyncUsecase<House, CreateHouseParams> {
  const CreateHouse(this._repo);
  final HouseRepo _repo;

  @override
  AsyncRequest<House> call(CreateHouseParams params) =>
      _repo.createHouse(name: params.name);
}
