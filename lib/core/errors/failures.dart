// Base failure class
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);
}

// Specific failures
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error occurred']) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure([String message = 'Cache error occurred']) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network error occurred']) : super(message);
}

class AuthFailure extends Failure {
  const AuthFailure(String message, [String? code]) : super(message, code);
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message) : super(message);
}

class FileFailure extends Failure {
  const FileFailure(String message) : super(message);
}
