import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/async_handlers/response.dart';
import 'package:aanda/src/core/error_handler/error_handler.dart';
import 'package:aanda/src/features/cost/data/datasources/category_emoji_local_datasource.dart';
import 'package:aanda/src/features/cost/data/datasources/category_emoji_remote_datasource.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';
import 'package:aanda/src/features/cost/domain/repo/category_emoji_repo.dart';

class CategoryEmojiRepoImpl with ErrorHandler implements CategoryEmojiRepo {
  CategoryEmojiRepoImpl({
    required CategoryEmojiRemoteDatasource remoteDatasource,
    required CategoryEmojiLocalDatasource localDatasource,
  }) : _remoteDatasource = remoteDatasource,
       _localDatasource = localDatasource;

  final CategoryEmojiRemoteDatasource _remoteDatasource;
  final CategoryEmojiLocalDatasource _localDatasource;

  @override
  AsyncRequest<List<CategoryEmoji>> getEmojis({bool forceRefresh = false}) {
    return asyncTryCatch(
      tryFunc: () async {
        // 1. Check local cache first unless forceRefresh is requested
        if (!forceRefresh) {
          final cached = await _localDatasource.getCachedEmojis();
          if (cached.isNotEmpty) {
            return SuccessRepoCall(data: cached);
          }
        }

        // 2. Fetch from remote
        final remote = await _remoteDatasource.getRemoteEmojis();

        // 3. Cache to local storage
        await _localDatasource.cacheEmojis(remote);

        return SuccessRepoCall(data: remote);
      },
    );
  }

  @override
  AsyncRequest<CategoryEmoji> uploadEmoji({
    required String name,
    required String emoji,
    String category = 'general',
    String? assetUrl,
  }) {
    return asyncTryCatch(
      tryFunc: () async {
        final created = await _remoteDatasource.uploadEmoji(
          name: name,
          emoji: emoji,
          category: category,
          assetUrl: assetUrl,
        );

        // Update local cache
        await _localDatasource.cacheEmojis([created]);

        return SuccessRepoCall(data: created);
      },
    );
  }

  @override
  AsyncRequest<String?> cacheEmojiAssetLocally(CategoryEmoji emoji) {
    return asyncTryCatch(
      tryFunc: () async {
        // If already cached, return local path
        final existingPath = await _localDatasource.getCachedAssetPath(
          emoji.id,
        );
        if (existingPath != null && existingPath.isNotEmpty) {
          return SuccessRepoCall(data: existingPath);
        }

        if (emoji.assetUrl == null || emoji.assetUrl!.isEmpty) {
          return const SuccessRepoCall(data: null);
        }

        // Future: download asset from emoji.assetUrl to local directory
        // and register path with _localDatasource.saveAssetLocally
        return const SuccessRepoCall(data: null);
      },
    );
  }
}
