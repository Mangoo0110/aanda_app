import 'package:aanda/src/features/cost/data/models/category_emoji_model.dart';

abstract interface class CategoryEmojiLocalDatasource {
  Future<List<CategoryEmojiModel>> getCachedEmojis();
  Future<void> cacheEmojis(List<CategoryEmojiModel> emojis);
  Future<String?> getCachedAssetPath(String emojiId);
  Future<void> saveAssetLocally(String emojiId, String localPath);
  Future<void> clearCache();
}

class CategoryEmojiLocalDatasourceImpl implements CategoryEmojiLocalDatasource {
  CategoryEmojiLocalDatasourceImpl();

  // In-memory cache for fast session access
  final Map<String, CategoryEmojiModel> _memoryCache = {};
  final Map<String, String> _assetPathCache = {};

  @override
  Future<List<CategoryEmojiModel>> getCachedEmojis() async {
    if (_memoryCache.isNotEmpty) {
      return _memoryCache.values.toList();
    }
    // Return empty if not yet cached so repository triggers remote fetch
    return [];
  }

  @override
  Future<void> cacheEmojis(List<CategoryEmojiModel> emojis) async {
    for (final item in emojis) {
      _memoryCache[item.id] = item;
    }
  }

  @override
  Future<String?> getCachedAssetPath(String emojiId) async {
    return _assetPathCache[emojiId] ?? _memoryCache[emojiId]?.localCachedPath;
  }

  @override
  Future<void> saveAssetLocally(String emojiId, String localPath) async {
    _assetPathCache[emojiId] = localPath;
    if (_memoryCache.containsKey(emojiId)) {
      _memoryCache[emojiId] = _memoryCache[emojiId]!.copyWith(
        localCachedPath: localPath,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    _memoryCache.clear();
    _assetPathCache.clear();
  }
}
