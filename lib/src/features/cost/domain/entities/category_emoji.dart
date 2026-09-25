class CategoryEmoji {
  const CategoryEmoji({
    required this.id,
    required this.emoji,
    required this.name,
    this.category = 'general',
    this.assetUrl,
    this.localCachedPath,
    this.costNature = 'variable',
    this.isFood = false,
    this.color,
  });

  final String id;
  final String emoji;
  final String name;
  final String category;
  final String? assetUrl;
  final String? localCachedPath;
  final String costNature;
  final bool isFood;
  final String? color;

  bool get isCached =>
      localCachedPath != null && localCachedPath!.trim().isNotEmpty;

  /// 15 relatable, in-house category presets with simple emojis & solid background colors
  static const List<CategoryEmoji> defaultEmojis = [
    CategoryEmoji(
      id: 'food_dining',
      name: 'Food & Dining',
      emoji: '🍳',
      category: 'food',
      costNature: 'variable',
      isFood: true,
      color: '#E11D48',
      assetUrl: 'assets/images/categories/food.jpg',
    ),
    CategoryEmoji(
      id: 'groceries_bazar',
      name: 'Groceries & Bazar',
      emoji: '🛒',
      category: 'shopping',
      costNature: 'variable',
      isFood: true,
      color: '#10B981',
      assetUrl: 'assets/images/categories/grocery.jpg',
    ),
    CategoryEmoji(
      id: 'snacks_tea',
      name: 'Snacks & Tea',
      emoji: '☕',
      category: 'food',
      costNature: 'variable',
      isFood: false,
      color: '#D97706',
      assetUrl: 'assets/images/categories/snacks.jpg',
    ),
    CategoryEmoji(
      id: 'household_supplies',
      name: 'Household Supplies',
      emoji: '🧴',
      category: 'shopping',
      costNature: 'variable',
      isFood: false,
      color: '#06B6D4',
      assetUrl: 'assets/images/categories/supplies.jpg',
    ),
    CategoryEmoji(
      id: 'transport_fuel',
      name: 'Transport & Fuel',
      emoji: '🚗',
      category: 'transport',
      costNature: 'variable',
      isFood: false,
      color: '#0284C7',
      assetUrl: 'assets/images/categories/transport.jpg',
    ),
    CategoryEmoji(
      id: 'rent_housing',
      name: 'Rent & Housing',
      emoji: '🏠',
      category: 'housing',
      costNature: 'fixed',
      isFood: false,
      color: '#0EA5E9',
      assetUrl: 'assets/images/categories/rent.jpg',
    ),
    CategoryEmoji(
      id: 'electricity_current',
      name: 'Electricity & Current',
      emoji: '💡',
      category: 'utilities',
      costNature: 'fixed',
      isFood: false,
      color: '#EAB308',
      assetUrl: 'assets/images/categories/electricity.jpg',
    ),
    CategoryEmoji(
      id: 'internet_wifi',
      name: 'Internet & WiFi',
      emoji: '📶',
      category: 'utilities',
      costNature: 'fixed',
      isFood: false,
      color: '#4F46E5',
      assetUrl: 'assets/images/categories/wifi.jpg',
    ),
    CategoryEmoji(
      id: 'gas_cylinder',
      name: 'Gas & Cylinder',
      emoji: '⛽',
      category: 'utilities',
      costNature: 'variable',
      isFood: false,
      color: '#0D9488',
      assetUrl: 'assets/images/categories/gas.jpg',
    ),
    CategoryEmoji(
      id: 'maid_cleaning',
      name: 'Maid & Cleaning',
      emoji: '🧹',
      category: 'maintenance',
      costNature: 'fixed',
      isFood: false,
      color: '#F97316',
      assetUrl: 'assets/images/categories/maid.jpg',
    ),
    CategoryEmoji(
      id: 'drinking_water',
      name: 'Drinking Water',
      emoji: '🥛',
      category: 'utilities',
      costNature: 'variable',
      isFood: false,
      color: '#0369A1',
      assetUrl: 'assets/images/categories/water.jpg',
    ),
    CategoryEmoji(
      id: 'maintenance_repairs',
      name: 'Maintenance & Repairs',
      emoji: '🔧',
      category: 'maintenance',
      costNature: 'variable',
      isFood: false,
      color: '#475569',
      assetUrl: 'assets/images/categories/maintenance.jpg',
    ),
    CategoryEmoji(
      id: 'health_medicine',
      name: 'Health & Medicine',
      emoji: '💊',
      category: 'health',
      costNature: 'variable',
      isFood: false,
      color: '#8B5CF6',
      assetUrl: 'assets/images/categories/health.jpg',
    ),
    CategoryEmoji(
      id: 'dining_out',
      name: 'Dining Out & Treats',
      emoji: '🎬',
      category: 'food',
      costNature: 'variable',
      isFood: false,
      color: '#7C3AED',
      assetUrl: 'assets/images/categories/dining.jpg',
    ),
    CategoryEmoji(
      id: 'waste_society',
      name: 'Waste & Society Service',
      emoji: '🗑️',
      category: 'utilities',
      costNature: 'fixed',
      isFood: false,
      color: '#14B8A6',
      assetUrl: 'assets/images/categories/waste.jpg',
    ),
  ];
}
