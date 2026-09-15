import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

final class AddCost implements AsyncUsecase<Cost, CreateCostData> {
  const AddCost(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<Cost> call(CreateCostData params) => _repo.addCost(params);
}
