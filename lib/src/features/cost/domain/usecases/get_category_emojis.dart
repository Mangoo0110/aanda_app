import 'package:aanda/src/core/async_handlers/async_request.dart';
import 'package:aanda/src/core/usecases/base_usecase.dart';
import 'package:aanda/src/features/cost/domain/entities/category_emoji.dart';
import 'package:aanda/src/features/cost/domain/repo/category_emoji_repo.dart';

class GetCategoryEmojisParams {
  const GetCategoryEmojisParams({this.forceRefresh = false});
  final bool forceRefresh;
}

final class GetCategoryEmojis
    implements AsyncUsecase<List<CategoryEmoji>, GetCategoryEmojisParams> {
  const GetCategoryEmojis(this._repo);
  final CategoryEmojiRepo _repo;

  @override
  AsyncRequest<List<CategoryEmoji>> call(GetCategoryEmojisParams params) =>
      _repo.getEmojis(forceRefresh: params.forceRefresh);
}
