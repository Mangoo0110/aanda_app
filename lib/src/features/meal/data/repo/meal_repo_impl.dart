import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/meal/data/datasources/meal_remote_datasource.dart';
import 'package:aanda/src/features/meal/domain/entities/meal_log.dart';
import 'package:aanda/src/features/meal/domain/repo/meal_repo.dart';

class MealRepoImpl with ErrorHandler implements MealRepo {
  const MealRepoImpl({required MealRemoteDatasource datasource})
      : _datasource = datasource;

  final MealRemoteDatasource _datasource;

  @override
  AsyncRequest<List<MealLog>> getMealLogs({
    required String houseId,
    required String cycleId,
    DateTime? date,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final logs = await _datasource.getMealLogs(
          houseId: houseId,
          cycleId: cycleId,
          date: date,
        );
        return SuccessRepoCall(data: logs);
      },
    );
  }

  @override
  AsyncRequest<MealLog> upsertMealLog({
    required String houseId,
    required String cycleId,
    required String userId,
    required DateTime logDate,
    required double breakfast,
    required double lunch,
    required double dinner,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final log = await _datasource.upsertMealLog(
          houseId: houseId,
          cycleId: cycleId,
          userId: userId,
          logDate: logDate,
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
        );
        return SuccessRepoCall(data: log);
      },
    );
  }
}
