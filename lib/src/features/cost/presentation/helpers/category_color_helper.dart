import 'package:flutter/material.dart';

class CategoryColorHelper {
  const CategoryColorHelper._();

  static const Color defaultColor = Color(0xFF0EA5E9);

  // High-contrast pairings: Emoji colors strongly contrast with background
  static const Map<String, Color> _emojiMap = {
    '🎬': Color(0xFF7C3AED), // Rich Purple (Black & white clapperboard pops)
    '⛽': Color(0xFF0D9488), // Deep Teal (Red gas pump pops with complementary contrast)
    '🚗': Color(0xFF0284C7), // Vibrant Ocean Blue (Red car pops with complementary contrast)
    '👩‍🍳': Color(0xFFF97316), // Orange (Maid / Service / Cooking)
    '💆': Color(0xFFF97316), // Orange
    '🧹': Color(0xFFF97316), // Orange (Broom pops on Orange)
    '🏠': Color(0xFF0EA5E9), // Sky Blue (Beige house with red roof pops)
    '💡': Color(0xFFEAB308), // Golden Yellow (White luminous bulb pops)
    '🍳': Color(0xFFE11D48), // Rose Red (Black pan & white/yellow egg pops)
    '🍲': Color(0xFFE11D48), // Rose Red
    '🛒': Color(0xFF10B981), // Emerald Green (Silver metal cart pops)
    '☕': Color(0xFFD97706), // Warm Amber (White coffee cup pops)
    '🧴': Color(0xFF06B6D4), // Cyan (Household supplies pop)
    '⚡': Color(0xFFEAB308), // Golden Yellow (Electric current pops)
    '📶': Color(0xFF4F46E5), // Royal Indigo (Signal bars pop)
    '🥛': Color(0xFF0369A1), // Deep Ocean Blue (White glass pops)
    '🔧': Color(0xFF475569), // Slate (Silver metallic wrench pops)
    '💊': Color(0xFF8B5CF6), // Purple (Red & white pill pops)
    '🍕': Color(0xFFD97706), // Warm Amber
    '🗑️': Color(0xFF14B8A6), // Mint Teal (Waste basket pops)
  };

  static const Map<String, Color> _keywordMap = {
    'food': Color(0xFFEF4444),
    'dining': Color(0xFFEF4444),
    'grocer': Color(0xFF10B981),
    'bazar': Color(0xFF10B981),
    'market': Color(0xFF10B981),
    'snack': Color(0xFFF59E0B),
    'tea': Color(0xFFF59E0B),
    'coffee': Color(0xFFF59E0B),
    'suppl': Color(0xFF06B6D4),
    'transport': Color(0xFFEC4899),
    'fuel': Color(0xFFEC4899),
    'rent': Color(0xFF0EA5E9),
    'house': Color(0xFF0EA5E9),
    'housing': Color(0xFF0EA5E9),
    'electric': Color(0xFFEAB308),
    'current': Color(0xFFEAB308),
    'light': Color(0xFFEAB308),
    'wifi': Color(0xFF6366F1),
    'internet': Color(0xFF6366F1),
    'gas': Color(0xFFEC4899),
    'cylinder': Color(0xFFEC4899),
    'maid': Color(0xFFF97316),
    'clean': Color(0xFFF97316),
    'water': Color(0xFF0284C7),
    'drink': Color(0xFF0284C7),
    'repair': Color(0xFF64748B),
    'maintenance': Color(0xFF64748B),
    'health': Color(0xFFDC2626),
    'medicine': Color(0xFFDC2626),
    'entertain': Color(0xFF8B5CF6),
    'movie': Color(0xFF8B5CF6),
    'treat': Color(0xFF8B5CF6),
    'waste': Color(0xFF14B8A6),
    'society': Color(0xFF14B8A6),
  };

  static const List<Color> vibrantPalette = [
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Hot Pink
    Color(0xFFF97316), // Orange
    Color(0xFF0EA5E9), // Sky Blue
    Color(0xFFEAB308), // Golden Yellow
    Color(0xFFEF4444), // Coral Red
    Color(0xFF10B981), // Emerald Green
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF43F5E), // Rose
    Color(0xFF14B8A6), // Mint Teal
    Color(0xFF84CC16), // Lime
  ];

  static Color fromHex(String? hexString) {
    if (hexString == null || hexString.isEmpty) return defaultColor;
    var hex = hexString.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    final val = int.tryParse(hex, radix: 16);
    return val != null ? Color(val) : defaultColor;
  }

  static Color getColorFor({String? icon, String? name, String? colorHex}) {
    if (colorHex != null && colorHex.isNotEmpty) {
      return fromHex(colorHex);
    }

    if (icon != null && icon.isNotEmpty) {
      for (final entry in _emojiMap.entries) {
        if (icon.contains(entry.key)) {
          return entry.value;
        }
      }
    }

    if (name != null && name.isNotEmpty) {
      final lower = name.toLowerCase();
      for (final entry in _keywordMap.entries) {
        if (lower.contains(entry.key)) {
          return entry.value;
        }
      }
      final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
      return vibrantPalette[hash % vibrantPalette.length];
    }

    if (icon != null && icon.isNotEmpty) {
      final hash = icon.codeUnits.fold(0, (acc, c) => acc + c);
      return vibrantPalette[hash % vibrantPalette.length];
    }

    return defaultColor;
  }
}
