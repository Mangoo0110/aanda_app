import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aanda/src/features/cost/data/models/category_emoji_model.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';

abstract interface class CategoryEmojiRemoteDatasource {
  Future<List<CategoryEmojiModel>> getRemoteEmojis();
  Future<CategoryEmojiModel> uploadEmoji({
    required String name,
    required String emoji,
    String category = 'general',
    String? assetUrl,
  });
}

class CategoryEmojiRemoteDatasourceImpl
    implements CategoryEmojiRemoteDatasource {
  CategoryEmojiRemoteDatasourceImpl({required SupabaseClient supabase})
    : _supabase = supabase;

  final SupabaseClient _supabase;

  @override
  Future<List<CategoryEmojiModel>> getRemoteEmojis() async {
    try {
      // 1. Edge function or table query
      final response = await _supabase
          .from('category_emojis')
          .select()
          .order('name');

      if (response.isNotEmpty) {
        return response.map((r) => CategoryEmojiModel.fromJson(r)).toList();
      }
    } catch (_) {
      // Graceful fallback to default emojis if table does not exist or network unavailable
    }

    return CategoryEmoji.defaultEmojis
        .map((e) => CategoryEmojiModel.fromEntity(e))
        .toList();
  }

  @override
  Future<CategoryEmojiModel> uploadEmoji({
    required String name,
    required String emoji,
    String category = 'general',
    String? assetUrl,
  }) async {
    final payload = {
      'name': name,
      'emoji': emoji,
      'category': category,
      if (assetUrl != null) 'asset_url': assetUrl,
    };

    try {
      final res = await _supabase
          .from('category_emojis')
          .insert(payload)
          .select()
          .single();
      return CategoryEmojiModel.fromJson(res);
    } catch (_) {
      // Offline / fallback creation
      return CategoryEmojiModel(
        id: 'emoji_${DateTime.now().millisecondsSinceEpoch}',
        emoji: emoji,
        name: name,
        category: category,
        assetUrl: assetUrl,
      );
    }
  }
}
