import 'app_error.dart';

typedef ServiceCall<T> = Future<T> Function();
typedef VoidServiceCall = Future<void> Function();

Future<T> tryOrThrow<T>(ServiceCall<T> call, {String? message}) async {
  try {
    return await call();
  } on AppError {
    rethrow;
  } catch (e) {
    throw AppError(
      message: message ?? 'Operation failed',
      type: ErrorType.database,
      originalError: e,
    );
  }
}

Future<void> tryOrThrowVoid(VoidServiceCall call, {String? message}) async {
  try {
    await call();
  } on AppError {
    rethrow;
  } catch (e) {
    throw AppError(
      message: message ?? 'Operation failed',
      type: ErrorType.database,
      originalError: e,
    );
  }
}
