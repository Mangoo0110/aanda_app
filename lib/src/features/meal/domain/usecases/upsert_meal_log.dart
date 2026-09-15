import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/domain/repo/meal_repo.dart';

class UpsertMealLogParams {
  const UpsertMealLogParams({
    required this.houseId,
    required this.cycleId,
    required this.userId,
    required this.logDate,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
  });

  final String houseId;
  final String cycleId;
  final String userId;
  final DateTime logDate;
  final double breakfast;
  final double lunch;
  final double dinner;
}

final class UpsertMealLog
    implements AsyncUsecase<MealLog, UpsertMealLogParams> {
  const UpsertMealLog(this._repo);

  final MealRepo _repo;

  @override
  AsyncRequest<MealLog> call(UpsertMealLogParams params) {
    return _repo.upsertMealLog(
      houseId: params.houseId,
      cycleId: params.cycleId,
      userId: params.userId,
      logDate: params.logDate,
      breakfast: params.breakfast,
      lunch: params.lunch,
      dinner: params.dinner,
    );
  }
}
