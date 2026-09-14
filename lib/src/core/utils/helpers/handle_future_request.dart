import 'package:pagination_pkg/pagination_pkg.dart';

import '../../async_handlers/async_request.dart';
import '../../async_handlers/response.dart';
import '../../shared/reactive_notifier/process_notifier.dart';
import '../debug/debug_service.dart';

/// Handles an async package request and updates process state.
///
/// This helper intentionally does not show snackbar/toast/dialog.
/// The host app should decide how success/error messages are presented.
Future<T?> handleFutureRequest<T>({
  required AsyncRequest<T> Function() request,
  Debugger? debugger,
  ProcessStatusNotifier? processStatusNotifier,
  void Function(T data)? onSuccess,
  void Function(FailedRepoCall<T> failure)? onError,
}) async {
  processStatusNotifier?.setLoading();

  final response = await request();

  if (response is SuccessRepoCall<T>) {
    processStatusNotifier?.setSuccess(message: response.message);

    final data = response.data;

    if (data != null) {
      onSuccess?.call(data);
    }

    debugger?.log('Success:: ${response.message}');

    return data;
  }

  if (response is FailedRepoCall<T>) {
    processStatusNotifier?.setEnabled(message: response.message);

    onError?.call(response);

    debugger?.log('Error:: $response');

    return null;
  }

  processStatusNotifier?.setEnabled();

  return null;
}

Future<PageFetchResponse<ItemUniqueKey, ItemData>>
handlePaginationRequest<ItemUniqueKey, ItemData>({
  required int page,
  required AsyncRequest<List<ItemData>> Function() request,
  required ItemUniqueKey Function(ItemData item) itemUniqueKey,
  bool Function(List<ItemData> items)? hasMore,
  Debugger? debugger,
  ProcessStatusNotifier? processStatusNotifier,
}) async {
  processStatusNotifier?.setLoading();

  final response = await request();

  if (response is SuccessRepoCall<List<ItemData>>) {
    processStatusNotifier?.setSuccess(message: response.message);

    final data = response.data;

    if (data == null) {
      return PaginationError(page: page, message: 'No data found!');
    }

    return PaginationPage(
      items: {for (final item in data) itemUniqueKey(item): item},
      hasMore: hasMore?.call(data) ?? data.isNotEmpty,
      page: page,
    );
  }

  if (response is FailedRepoCall<List<ItemData>>) {
    processStatusNotifier?.setEnabled(message: response.message);

    debugger?.log('Error:: $response');

    return PaginationError(page: page, message: response.message);
  }

  processStatusNotifier?.setEnabled();

  return PaginationError(
    page: page,
    message: 'Something went wrong.',
    isCritical: true,
  );
}
