import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class DeleteCostParams {
  const DeleteCostParams({required this.costId});
  final String costId;
}

final class DeleteCost implements AsyncUsecase<void, DeleteCostParams> {
  const DeleteCost(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<void> call(DeleteCostParams params) =>
      _repo.deleteCost(costId: params.costId);
}
