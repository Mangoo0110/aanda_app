import 'package:aanda/src/features/cost/data/models/cost_model.dart';
import 'package:aanda/src/features/dashboard/data/models/dashboard_activity_model.dart';
import 'package:aanda/src/features/dashboard/domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.month,
    required super.personalSpent,
    required super.totalHouseSpent,
    required super.myHouseContribution,
    required super.activities,
    super.recentCosts = const [],
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['activities'] as List<dynamic>? ?? const [];
    final activities = rawActivities
        .map((a) => DashboardActivityModel.fromJson(a as Map<String, dynamic>))
        .toList();

    final rawCosts = json['recent_costs'] as List<dynamic>? ??
        json['costs'] as List<dynamic>? ??
        const [];
    final recentCosts = rawCosts
        .map((c) => CostModel.fromJson(c as Map<String, dynamic>))
        .toList();

    return DashboardSummaryModel(
      month: json['month'] as String? ?? '',
      personalSpent: (json['personal_spent'] as num?)?.toDouble() ?? 0.0,
      totalHouseSpent: (json['total_house_spent'] as num?)?.toDouble() ?? 0.0,
      myHouseContribution:
          (json['my_house_contribution'] as num?)?.toDouble() ?? 0.0,
      activities: activities,
      recentCosts: recentCosts,
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'personal_spent': personalSpent,
    'total_house_spent': totalHouseSpent,
    'my_house_contribution': myHouseContribution,
    'activities': activities
        .map((a) => (a as DashboardActivityModel).toJson())
        .toList(),
  };
}
