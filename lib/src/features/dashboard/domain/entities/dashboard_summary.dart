import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.month,
    required this.personalSpent,
    required this.totalHouseSpent,
    required this.myHouseContribution,
    required this.activities,
  });

  final String month;
  final double personalSpent;
  final double totalHouseSpent;
  final double myHouseContribution;
  final List<DashboardActivity> activities;
}
