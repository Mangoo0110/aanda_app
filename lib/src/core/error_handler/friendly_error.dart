class FriendlyError {
  const FriendlyError({
    required this.title,
    required this.message,
    this.isNetwork = false,
  });

  final String title;
  final String message;
  final bool isNetwork;

  static FriendlyError from(Object? error) {
    if (error == null) {
      return const FriendlyError(
        title: 'Something unexpected happened',
        message: 'Please try again later!',
      );
    }

    final raw = error.toString().toLowerCase();

    if (raw.contains('socket') ||
        raw.contains('failed host lookup') ||
        raw.contains('network') ||
        raw.contains('connection refused') ||
        raw.contains('connection timed out') ||
        raw.contains('clientexception') ||
        raw.contains('offline') ||
        raw.contains('no internet') ||
        raw.contains('handshake') ||
        raw.contains('networkerror') ||
        raw.contains('xmlhttprequest')) {
      return const FriendlyError(
        title: 'No internet connection',
        message: 'Please check your internet connection and try again.',
        isNetwork: true,
      );
    }

    return const FriendlyError(
      title: 'Something unexpected happened',
      message: 'Please try again later!',
    );
  }
}
