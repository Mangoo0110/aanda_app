import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';

abstract interface class DashboardRepo {
  AsyncRequest<DashboardSummary> getDashboardSummary({
    String? houseId,
    String? month,
  });
}
