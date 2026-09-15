import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/domain/repo/meal_repo.dart';

class GetMealLogsParams {
  const GetMealLogsParams({
    required this.houseId,
    required this.cycleId,
    this.date,
  });

  final String houseId;
  final String cycleId;
  final DateTime? date;
}

final class GetMealLogs
    implements AsyncUsecase<List<MealLog>, GetMealLogsParams> {
  const GetMealLogs(this._repo);

  final MealRepo _repo;

  @override
  AsyncRequest<List<MealLog>> call(GetMealLogsParams params) {
    return _repo.getMealLogs(
      houseId: params.houseId,
      cycleId: params.cycleId,
      date: params.date,
    );
  }
}
