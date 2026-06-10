import 'dart:io';
import 'app_error.dart';

typedef ServiceCall<T> = Future<T> Function();
typedef VoidServiceCall = Future<void> Function();

ErrorType _mapException(dynamic e, ErrorType defaultType) {
  final errStr = e.runtimeType.toString();
  if (e is SocketException || errStr.contains('SocketException') || errStr.contains('ClientException')) {
    return ErrorType.network;
  }
  if (e is PathNotFoundException || errStr.contains('PathNotFoundException')) {
    return ErrorType.notFound;
  }
  if (errStr.contains('DatabaseException') || errStr.contains('SqliteException')) {
    return ErrorType.database;
  }
  return defaultType;
}

Future<T> tryOrThrow<T>(
  ServiceCall<T> call, {
  String? message,
  ErrorType type = ErrorType.unknown,
}) async {
  try {
    return await call();
  } on AppError {
    rethrow;
  } catch (e) {
    throw AppError(
      message: message ?? 'Operation failed',
      type: _mapException(e, type),
      originalError: e,
    );
  }
}

Future<void> tryOrThrowVoid(
  VoidServiceCall call, {
  String? message,
  ErrorType type = ErrorType.unknown,
}) async {
  try {
    await call();
  } on AppError {
    rethrow;
  } catch (e) {
    throw AppError(
      message: message ?? 'Operation failed',
      type: _mapException(e, type),
      originalError: e,
    );
  }
}

