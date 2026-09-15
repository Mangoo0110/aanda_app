import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class GetCostCategoriesParams {
  const GetCostCategoriesParams({this.houseId});
  final String? houseId;
}

final class GetCostCategories
    implements AsyncUsecase<List<CostCategory>, GetCostCategoriesParams> {
  const GetCostCategories(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<List<CostCategory>> call(GetCostCategoriesParams params) =>
      _repo.getCategories(houseId: params.houseId);
}
