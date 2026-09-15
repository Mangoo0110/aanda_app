enum DashboardActivityType { expense, meal }

class DashboardActivity {
  const DashboardActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.tag,
    required this.timestamp,
    this.amount,
  });

  final String id;
  final DashboardActivityType type;
  final String title;
  final String tag;
  final DateTime timestamp;
  final double? amount;

  bool get isExpense => type == DashboardActivityType.expense;
  bool get isMeal => type == DashboardActivityType.meal;
}
