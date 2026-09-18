class CategoryEmoji {
  const CategoryEmoji({
    required this.id,
    required this.emoji,
    required this.name,
    this.category = 'general',
    this.assetUrl,
    this.localCachedPath,
  });

  final String id;
  final String emoji;
  final String name;
  final String category;
  final String? assetUrl;
  final String? localCachedPath;

  bool get isCached =>
      localCachedPath != null && localCachedPath!.trim().isNotEmpty;

  /// Default predefined emoji presets available immediately offline.
  static const List<CategoryEmoji> defaultEmojis = [
    CategoryEmoji(
      id: 'emoji_electricity',
      emoji: '⚡',
      name: 'Electricity',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_house',
      emoji: '🏠',
      name: 'Rent & Housing',
      category: 'housing',
    ),
    CategoryEmoji(
      id: 'emoji_cart',
      emoji: '🛒',
      name: 'Groceries',
      category: 'shopping',
    ),
    CategoryEmoji(
      id: 'emoji_cleaning',
      emoji: '🧹',
      name: 'Cleaning & Maid',
      category: 'maintenance',
    ),
    CategoryEmoji(
      id: 'emoji_chart',
      emoji: '📊',
      name: 'Bills & Accounts',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_water',
      emoji: '💧',
      name: 'Water & Gas',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_food',
      emoji: '🍳',
      name: 'Cooking & Food',
      category: 'food',
    ),
    CategoryEmoji(
      id: 'emoji_car',
      emoji: '🚗',
      name: 'Transport & Fuel',
      category: 'transport',
    ),
    CategoryEmoji(
      id: 'emoji_health',
      emoji: '🩺',
      name: 'Medical & Health',
      category: 'health',
    ),
    CategoryEmoji(
      id: 'emoji_box',
      emoji: '📦',
      name: 'Deliveries',
      category: 'shopping',
    ),
    CategoryEmoji(
      id: 'emoji_security',
      emoji: '🛡️',
      name: 'Security & Guard',
      category: 'housing',
    ),
    CategoryEmoji(
      id: 'emoji_coffee',
      emoji: '☕',
      name: 'Snacks & Tea',
      category: 'food',
    ),
    CategoryEmoji(
      id: 'emoji_bulb',
      emoji: '💡',
      name: 'Lighting',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_wifi',
      emoji: '📶',
      name: 'Internet & WiFi',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_pizza',
      emoji: '🍕',
      name: 'Dining Out',
      category: 'food',
    ),
    CategoryEmoji(
      id: 'emoji_gas',
      emoji: '⛽',
      name: 'Gas / Cylinder',
      category: 'utilities',
    ),
    CategoryEmoji(
      id: 'emoji_fitness',
      emoji: '🏋️',
      name: 'Fitness & Sports',
      category: 'lifestyle',
    ),
    CategoryEmoji(
      id: 'emoji_movie',
      emoji: '🎬',
      name: 'Entertainment',
      category: 'lifestyle',
    ),
  ];
}
