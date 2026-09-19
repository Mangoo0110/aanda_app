import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../async_handlers/async_request.dart';
import '../async_handlers/response.dart';
import '../utils/debug/debug_service.dart';

/// Centralized error handler used by repository implementations.
///
/// Keeps repository methods clean and converts raw database, network,
/// and service-provider errors into friendly, actionable messages for the user.
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
        message:
            'No internet connection. Please check your network and try again.',
        exception: e,
        stackTrace: s,
      );
    } on TimeoutException catch (e, s) {
      error = FailedRepoCall<T>(
        message: 'The request took too long. Please try again.',
        exception: e,
        stackTrace: s,
      );
    } on HttpException catch (e, s) {
      error = FailedRepoCall<T>(
        message: 'Unable to connect to the server. Please try again.',
        exception: e,
        stackTrace: s,
      );
    } on PostgrestException catch (e, s) {
      error = FailedRepoCall<T>(
        message: _formatPostgrestError(e),
        exception: e,
        stackTrace: s,
      );
    } on AuthException catch (e, s) {
      error = FailedRepoCall<T>(
        message: _formatAuthError(e),
        exception: e,
        stackTrace: s,
      );
    } on FunctionException catch (e, s) {
      error = FailedRepoCall<T>(
        message: _formatFunctionError(e),
        exception: e,
        stackTrace: s,
      );
    } catch (e, s) {
      error = FailedRepoCall<T>(
        message: _friendlyErrorMessage(e),
        exception: e is Exception ? e : Exception(e.toString()),
        stackTrace: s,
      );
    }

    if (kDebugMode) {
      debugger?.log(
        'ErrorHandler caught: ${error.message} (${error.exception})',
      );
    }

    return error;
  }

  /// Converts PostgreSQL / PostgREST errors into clean, friendly user messages.
  String _formatPostgrestError(PostgrestException e) {
    final code = e.code;
    final rawMsg = e.message.toLowerCase();
    final details = e.details?.toString().toLowerCase() ?? '';
    final hint = e.hint?.toString().toLowerCase() ?? '';
    final combined = '$rawMsg $details $hint';

    // 1. Invalid input syntax (PostgreSQL code 22P02)
    if (code == '22P02' || combined.contains('invalid input syntax')) {
      if (combined.contains('uuid')) {
        return 'A required selection is missing or invalid. Please re-select the item.';
      }
      if (combined.contains('numeric') ||
          combined.contains('integer') ||
          combined.contains('double')) {
        return 'Please enter a valid number for the amount.';
      }
      if (combined.contains('date') || combined.contains('timestamp')) {
        return 'The selected date is invalid. Please pick a valid date.';
      }
      return 'One of the inputs is invalid. Please check your entries.';
    }

    // 2. Missing required field (PostgreSQL code 23502 not-null violation)
    if (code == '23502' ||
        combined.contains('violates not-null constraint') ||
        combined.contains('null value in column')) {
      final match = RegExp(r'column "([^"]+)"').firstMatch(combined);
      if (match != null) {
        final field = _friendlyFieldName(match.group(1));
        return 'Please provide $field.';
      }
      return 'A required field is missing. Please fill in all required fields.';
    }

    // 3. Unique violation / Duplicate entry (PostgreSQL code 23505)
    if (code == '23505' ||
        combined.contains('duplicate key') ||
        combined.contains('already exists')) {
      return 'This entry already exists. Please use a different name or value.';
    }

    // 4. Foreign key violation (PostgreSQL code 23503)
    if (code == '23503' || combined.contains('violates foreign key constraint')) {
      return 'The selected item or member is no longer available.';
    }

    // 5. Check constraint violation (PostgreSQL code 23514)
    if (code == '23514' || combined.contains('check constraint')) {
      return 'The entered value does not meet requirements. Please verify your input.';
    }

    // 6. Permission / RLS policy error (PostgreSQL code 42501)
    if (code == '42501' ||
        combined.contains('row-level security') ||
        combined.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }

    // 7. Not found (PostgREST code PGRST116)
    if (code == 'PGRST116' || combined.contains('0 rows')) {
      return 'The requested information could not be found.';
    }

    // 8. Undefined table/column or schema issue (42P01, 42703)
    if (code == '42P01' ||
        code == '42703' ||
        combined.contains('does not exist')) {
      return 'This service is temporarily unavailable. Please try again shortly.';
    }

    // 9. Server busy / connection limits (53300, 53400, 57P01)
    if (code != null && (code.startsWith('53') || code.startsWith('57'))) {
      return 'The server is currently busy. Please wait a moment and try again.';
    }

    return _sanitizeMessage(e.message);
  }

  /// Converts Auth exceptions into user-friendly messages.
  String _formatAuthError(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (msg.contains('password should be')) {
      return 'Please choose a stronger password.';
    }
    return _sanitizeMessage(e.message);
  }

  /// Converts Edge Function exceptions into user-friendly messages.
  String _formatFunctionError(FunctionException e) {
    if (e.details is Map) {
      final map = e.details as Map;
      if (map['error'] != null) return map['error'].toString();
      if (map['message'] != null) return map['message'].toString();
    }
    if (e.details is String && (e.details as String).isNotEmpty) {
      return e.details as String;
    }
    if (e.reasonPhrase != null && e.reasonPhrase!.isNotEmpty) {
      return e.reasonPhrase!;
    }
    return 'The service request failed. Please try again.';
  }

  /// Maps database column names to user-friendly field descriptions.
  String _friendlyFieldName(String? col) {
    if (col == null) return 'this field';
    switch (col.toLowerCase()) {
      case 'name':
        return 'a name';
      case 'amount':
        return 'an amount';
      case 'house_id':
        return 'a shared house';
      case 'paid_by':
        return 'the member who paid';
      case 'cycle_id':
        return 'the active meal sprint / cycle';
      case 'category_id':
        return 'a category';
      case 'purchase_date':
      case 'log_date':
        return 'a valid date';
      case 'email':
        return 'a valid email address';
      case 'password':
        return 'a password';
      default:
        return 'the ${col.replaceAll('_', ' ')}';
    }
  }

  /// Fallback friendly parser for any dynamic exception or wrapped error.
  String _friendlyErrorMessage(dynamic e) {
    if (e is PostgrestException) return _formatPostgrestError(e);
    if (e is AuthException) return _formatAuthError(e);
    if (e is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (e is TimeoutException) {
      return 'The request took too long. Please try again.';
    }
    if (e is HttpException) {
      return 'Unable to connect to the server. Please try again.';
    }
    if (e is FormatException) {
      return 'Invalid data format received. Please try again.';
    }

    final raw = e.toString();
    return _sanitizeMessage(raw);
  }

  /// Strips technical wrappers, provider names, and SQL jargon,
  /// ensuring the user never sees "PostgrestException(...)" or raw code.
  String _sanitizeMessage(String raw) {
    final lower = raw.toLowerCase();

    // Catch stringified Postgrest / Postgres errors
    if (lower.contains('postgrest') ||
        lower.contains('syntax for type') ||
        lower.contains('invalid input syntax')) {
      if (lower.contains('uuid')) {
        return 'A required selection is missing or invalid. Please re-select the item.';
      }
      if (lower.contains('numeric') || lower.contains('integer')) {
        return 'Please enter a valid number for the amount.';
      }
      return 'One of the entered details is invalid. Please check your inputs.';
    }

    if (lower.contains('violates not-null') ||
        lower.contains('null value in column')) {
      return 'A required field is missing. Please fill in all required fields.';
    }

    if (lower.contains('duplicate key') || lower.contains('already exists')) {
      return 'This entry already exists. Please use a different name.';
    }

    if (lower.contains('foreign key') ||
        lower.contains('violates foreign key')) {
      return 'The selected item or member is no longer available.';
    }

    if (lower.contains('row-level security') ||
        lower.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }

    // Strip common exception prefixes
    var cleaned = raw
        .replaceFirst(RegExp(r'^(Exception:\s*)+'), '')
        .replaceFirst(RegExp(r'^[A-Za-z0-9_]*Exception:\s*'), '')
        .trim();

    // If it still looks like an internal class toString, e.g. SomeError(...)
    final wrapperMatch = RegExp(
      r'^[A-Za-z0-9_]+\((.*)\)$',
    ).firstMatch(cleaned);
    if (wrapperMatch != null) {
      cleaned = wrapperMatch.group(1) ?? '';
    }

    // If cleaned string has database / SQL / server provider terms, hide them
    final cleanedLower = cleaned.toLowerCase();
    if (cleanedLower.contains('supabase') ||
        cleanedLower.contains('postgres') ||
        cleanedLower.contains('relation ') ||
        cleanedLower.contains('column ') ||
        cleanedLower.contains('table ') ||
        cleanedLower.contains('select ') ||
        cleanedLower.contains('insert ') ||
        cleanedLower.contains('update ') ||
        cleanedLower.contains('constraint ') ||
        cleanedLower.isEmpty) {
      return 'Unable to complete request. Please check your inputs and try again.';
    }

    return cleaned;
  }

  // ignore: unused_element
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
