import 'response.dart';

/// Standard async operation result used throughout the package.
typedef AsyncRequest<T> = Future<RepoResponse<T>>;
