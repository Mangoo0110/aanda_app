import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';

abstract interface class CategoryEmojiRepo {
  /// Fetches available category emojis.
  /// If cached locally, returns the cached emojis. Otherwise fetches from remote,
  /// saves to local device storage, and returns.
  AsyncRequest<List<CategoryEmoji>> getEmojis({bool forceRefresh = false});

  /// Uploads a new emoji / category icon to the database and caches it.
  AsyncRequest<CategoryEmoji> uploadEmoji({
    required String name,
    required String emoji,
    String category = 'general',
    String? assetUrl,
  });

  /// Caches a remote emoji asset image/SVG to local storage if not already cached.
  AsyncRequest<String?> cacheEmojiAssetLocally(CategoryEmoji emoji);
}
