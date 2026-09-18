import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

final class CreateCostCategory
    implements AsyncUsecase<CostCategory, CreateCostCategoryData> {
  const CreateCostCategory(this._repo);
  final CostRepo _repo;

  @override
  AsyncRequest<CostCategory> call(CreateCostCategoryData params) =>
      _repo.createCategory(params);
}
