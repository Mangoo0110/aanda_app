enum SprintStatus { open, closed }

class Sprint {
  const Sprint({
    required this.id,
    required this.houseId,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.breakfastWeight = 1.0,
    this.lunchWeight = 1.0,
    this.dinnerWeight = 1.0,
    this.closedAt,
    this.createdBy,
  });

  final String id;
  final String houseId;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final SprintStatus status;
  final double breakfastWeight;
  final double lunchWeight;
  final double dinnerWeight;
  final DateTime? closedAt;
  final String? createdBy;

  bool get isOpen => status == SprintStatus.open;
  bool get isClosed => status == SprintStatus.closed;

  String get dateRangeFormatted {
    final startStr = '${startDate.day} ${_monthName(startDate.month)}';
    final endStr = '${endDate.day} ${_monthName(endDate.month)}';
    return '$startStr - $endStr';
  }

  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}
