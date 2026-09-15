import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';
import 'package:aanda/src/features/dashboard/domain/repo/dashboard_repo.dart';

class GetDashboardSummaryParams {
  const GetDashboardSummaryParams({
    this.houseId,
    this.month,
  });

  final String? houseId;
  final String? month;
}

final class GetDashboardSummary
    implements AsyncUsecase<DashboardSummary, GetDashboardSummaryParams> {
  const GetDashboardSummary(this._repo);

  final DashboardRepo _repo;

  @override
  AsyncRequest<DashboardSummary> call(GetDashboardSummaryParams params) {
    return _repo.getDashboardSummary(
      houseId: params.houseId,
      month: params.month,
    );
  }
}
