// Base failure class
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);
}

// Specific failures
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, [super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class FileFailure extends Failure {
  const FileFailure(super.message);
}
