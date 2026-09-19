import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:aanda/src/features/dashboard/domain/repo/dashboard_repo.dart';

final class DashboardRepoImpl with ErrorHandler implements DashboardRepo {
  DashboardRepoImpl({required DashboardRemoteDatasource datasource})
    : _datasource = datasource;

  final DashboardRemoteDatasource _datasource;

  @override
  AsyncRequest<DashboardSummary> getDashboardSummary({
    String? houseId,
    String? cycleId,
    DateTime? startDate,
    DateTime? endDate,
    String? month,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final summary = await _datasource.getDashboardSummary(
          houseId: houseId,
          cycleId: cycleId,
          startDate: startDate,
          endDate: endDate,
          month: month,
        );
        return SuccessRepoCall(data: summary);
      },
    );
  }
}
