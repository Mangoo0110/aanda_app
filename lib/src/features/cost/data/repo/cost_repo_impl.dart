import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/cost/data/datasources/cost_remote_datasource.dart';
import 'package:aanda/src/features/cost/domain/entities/cost.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_category.dart';
import 'package:aanda/src/features/cost/domain/entities/cost_scope.dart';
import 'package:aanda/src/features/cost/domain/repo/cost_repo.dart';

class CostRepoImpl with ErrorHandler implements CostRepo {
  CostRepoImpl({required CostRemoteDatasource datasource})
    : _datasource = datasource;

  final CostRemoteDatasource _datasource;

  @override
  AsyncRequest<List<Cost>> getCosts({
    String? houseId,
    CostScope? scope,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final costs = await _datasource.getCosts(
          houseId: houseId,
          scope: scope,
          startDate: startDate,
          endDate: endDate,
        );
        return SuccessRepoCall(data: costs);
      },
    );
  }

  @override
  AsyncRequest<Cost> addCost(CreateCostData data) {
    return asyncTryCatch(
      tryFunc: () async {
        final cost = await _datasource.addCost(data);
        return SuccessRepoCall(data: cost);
      },
    );
  }

  @override
  AsyncRequest<Cost> updateCost(UpdateCostData data) {
    return asyncTryCatch(
      tryFunc: () async {
        final cost = await _datasource.updateCost(data);
        return SuccessRepoCall(data: cost);
      },
    );
  }

  @override
  AsyncRequest<void> deleteCost({required String costId}) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.deleteCost(costId: costId);
        return const SuccessRepoCall();
      },
    );
  }

  @override
  AsyncRequest<List<CostCategory>> getCategories({String? houseId}) {
    return asyncTryCatch(
      tryFunc: () async {
        final categories = await _datasource.getCategories(houseId: houseId);
        return SuccessRepoCall(data: categories);
      },
    );
  }

  @override
  AsyncRequest<CostCategory> createCategory(CreateCostCategoryData data) {
    return asyncTryCatch(
      tryFunc: () async {
        final category = await _datasource.createCategory(data);
        return SuccessRepoCall(data: category);
      },
    );
  }

  @override
  AsyncRequest<void> deleteCategory(String categoryId) {
    return asyncTryCatch(
      tryFunc: () async {
        await _datasource.deleteCategory(categoryId);
        return const SuccessRepoCall(data: null);
      },
    );
  }
}
