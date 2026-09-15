import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

final class UpdateCost implements AsyncUsecase<Cost, UpdateCostData> {
  const UpdateCost(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<Cost> call(UpdateCostData params) => _repo.updateCost(params);
}
