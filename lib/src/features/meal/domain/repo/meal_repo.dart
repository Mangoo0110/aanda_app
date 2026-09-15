import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';

abstract interface class MealRepo {
  AsyncRequest<List<MealLog>> getMealLogs({
    required String houseId,
    required String cycleId,
    DateTime? date,
  });

  AsyncRequest<MealLog> upsertMealLog({
    required String houseId,
    required String cycleId,
    required String userId,
    required DateTime logDate,
    required double breakfast,
    required double lunch,
    required double dinner,
  });
}
