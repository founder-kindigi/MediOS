enum ErrorType {
  validation,
  authentication,
  notFound,
  database,
  network,
  permission,
  unknown,
}

class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;

  const AppError({
    required this.message,
    this.type = ErrorType.unknown,
    this.originalError,
  });

  @override
  String toString() => message;

  String get userMessage {
    switch (type) {
      case ErrorType.authentication:
        return 'Invalid username or password';
      case ErrorType.database:
        return 'A database error occurred. Please try again.';
      case ErrorType.notFound:
        return 'The requested item was not found.';
      case ErrorType.validation:
        return message;
      case ErrorType.network:
        return 'A network error occurred. Please check your connection.';
      case ErrorType.permission:
        return 'You do not have permission to perform this action.';
      case ErrorType.unknown:
        return 'Something went wrong. Please try again.';
    }
  }
}
