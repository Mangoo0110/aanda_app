import 'package:aanda/src/features/dashboard/domain/entities/dashboard_activity.dart';

class DashboardActivityModel extends DashboardActivity {
  const DashboardActivityModel({
    required super.id,
    required super.type,
    required super.title,
    required super.tag,
    required super.timestamp,
    super.amount,
  });

  factory DashboardActivityModel.fromJson(Map<String, dynamic> json) {
    return DashboardActivityModel(
      id: json['id'] as String? ?? '',
      type: (json['type'] as String?) == 'meal'
          ? DashboardActivityType.meal
          : DashboardActivityType.expense,
      title: json['title'] as String? ?? '',
      tag: json['tag'] as String? ?? '',
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title,
    'tag': tag,
    'timestamp': timestamp.toIso8601String(),
    if (amount != null) 'amount': amount,
  };
}
