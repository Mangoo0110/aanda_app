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

  /// Built-in predefined categories available for personal expenses immediately.
  static const List<CostCategory> predefinedCategories = [
    CostCategory(
      id: 'predefined_food',
      name: 'Food & Dining',
      icon: 'restaurant',
      isFood: true,
    ),
    CostCategory(
      id: 'predefined_grocery',
      name: 'Groceries',
      icon: 'shopping_basket',
      isFood: true,
    ),
    CostCategory(
      id: 'predefined_transport',
      name: 'Transport',
      icon: 'directions_bus',
    ),
    CostCategory(
      id: 'predefined_utilities',
      name: 'Bills & Utilities',
      icon: 'flash_on',
    ),
    CostCategory(id: 'predefined_rent', name: 'Rent', icon: 'home'),
    CostCategory(
      id: 'predefined_shopping',
      name: 'Shopping',
      icon: 'shopping_bag',
    ),
    CostCategory(
      id: 'predefined_health',
      name: 'Health & Medical',
      icon: 'medical_services',
    ),
    CostCategory(
      id: 'predefined_entertainment',
      name: 'Entertainment',
      icon: 'movie',
    ),
    CostCategory(id: 'predefined_other', name: 'Other', icon: 'more_horiz'),
  ];
}
