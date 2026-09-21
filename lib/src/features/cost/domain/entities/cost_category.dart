class CostCategory {
  const CostCategory({
    required this.id,
    required this.name,
    this.icon,
    this.isFood = false,
    this.houseId,
    this.defaultAmount,
    this.costNature,
  });

  final String id;
  final String name;
  final String? icon;
  final bool isFood;
  final String? houseId;
  final double? defaultAmount;
  final String? costNature; // 'fixed' or 'variable'

  bool get isPersonalPredefined => houseId == null;

  /// Dynamic categories are loaded from database per house/account.
  static const List<CostCategory> predefinedCategories = [];
}
