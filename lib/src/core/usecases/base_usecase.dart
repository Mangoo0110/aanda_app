import '../async_handlers/async_request.dart';

/// Represents a use case that performs an async operation
/// and returns a standardized data response.
abstract interface class AsyncUsecase<SuccessType, Params> {
  AsyncRequest<SuccessType> call(Params params);
}

/// Represents a synchronous use case.
abstract interface class Usecase<SuccessType, Params> {
  SuccessType call(Params params);
}

/// Represents a use case that continuously emits data.
///
/// Stream use cases should use normal Dart stream errors
/// instead of wrapping every emitted value with a response object.
abstract interface class StreamUsecase<SuccessType, Params> {
  Stream<SuccessType> call(Params params);
}

/// Used when a use case does not require input parameters.
final class NoParams {
  const NoParams();
}
