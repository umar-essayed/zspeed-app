/// Core failure types for repository and viewmodel error propagation.
sealed class Failure {
  final String message;
  final StackTrace? stackTrace;

  Failure(this.message, [this.stackTrace]);
}

class NetworkFailure extends Failure {
  final int? statusCode;

  NetworkFailure(
    String message, {
    this.statusCode,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);
}

class CacheFailure extends Failure {
  CacheFailure(super.message, [super.stackTrace]);
}

class AuthFailure extends Failure {
  AuthFailure(super.message, [super.stackTrace]);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  ValidationFailure(
    String message, {
    this.fieldErrors,
    StackTrace? stackTrace,
  }) : super(message, stackTrace);
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure(super.message, [super.stackTrace]);
}

class ServerFailure extends Failure {
  ServerFailure(super.message, [super.stackTrace]);
}

class UserBlockedFailure extends Failure {
  final String? reason;
  UserBlockedFailure([
    String? message,
    this.reason,
    StackTrace? stackTrace,
  ]) : super(
          message ?? 'Your account has been suspended. Please contact customer support.',
          stackTrace,
        );
}

class RegistrationDisabledFailure extends Failure {
  RegistrationDisabledFailure([
    String? message,
    StackTrace? stackTrace,
  ]) : super(
          message ?? 'New user registration is currently disabled. Please try again later.',
          stackTrace,
        );
}
