/// Internal result wrapper for data operations.
///
/// Used to return a predictable success/failure shape
/// without leaking raw exceptions across layers.
abstract class RepoResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const RepoResponse({
    required this.success,
    required this.message,
    required this.data,
  });
}

/// Successful data operation result.
final class SuccessRepoCall<T> extends RepoResponse<T> {
  const SuccessRepoCall({super.message = 'Success.', super.data})
    : super(success: true);
}

/// Failed data operation result.
final class FailedRepoCall<T> extends RepoResponse<T> {
  final Exception exception;
  final StackTrace stackTrace;

  const FailedRepoCall({
    super.message = 'Something went wrong.',
    super.data,
    required this.exception,
    required this.stackTrace,
  }) : super(success: false);

  @override
  String toString() {
    return '''
      FailedRepoCall{
      message: $message,
      data: $data,
      exception: $exception,
      stackTrace: $stackTrace
      }
      ''';
  }
}
