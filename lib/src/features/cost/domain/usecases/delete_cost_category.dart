import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class DeleteCostCategoryParams {
  const DeleteCostCategoryParams({required this.categoryId});
  final String categoryId;
}

final class DeleteCostCategory
    implements AsyncUsecase<void, DeleteCostCategoryParams> {
  const DeleteCostCategory(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<void> call(DeleteCostCategoryParams params) =>
      _repo.deleteCategory(params.categoryId);
}
