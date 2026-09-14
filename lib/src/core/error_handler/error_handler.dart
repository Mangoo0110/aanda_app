import 'dart:io';

import 'package:flutter/foundation.dart';

import '../async_handlers/async_request.dart';
import '../async_handlers/response.dart';
import '../utils/debug/debug_service.dart';

/// Centralized error handler used by repository implementations.
///
/// Keeps repository methods clean and avoids repeated try-catch blocks.
mixin class ErrorHandler {
  AsyncRequest<T> asyncTryCatch<T>({
    required Future<RepoResponse<T>> Function() tryFunc,
    Debugger? debugger,
  }) async {
    late final FailedRepoCall<T> error;

    try {
      return await tryFunc();
    } on SocketException catch (e, s) {
      error = FailedRepoCall<T>(
        message: 'Internet connection failed.',
        exception: e,
        stackTrace: s,
      );
    } catch (e, s) {
      error = FailedRepoCall<T>(
        message: 'Something went wrong.',
        exception: Exception(e.toString()),
        stackTrace: s,
      );
    }

    if (kDebugMode) {
      debugger?.log('SuperChat error: ${error.toString()}');
    }

    return error;
  }

  String _friendlyStatusMessage(int? statusCode, String responseMessage) {
    switch (statusCode) {
      case 400:
        return 'The request could not be completed.';
      case 401:
        return 'Unauthorized access.';
      case 403:
        return 'You do not have permission to view this information.';
      case 404:
        return 'We could not find this information.';
      case 408:
        return 'The request took too long. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case final code? when code >= 500:
        return 'The server is having trouble. Please try again shortly.';
      default:
        return responseMessage;
    }
  }
}
