// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

// Specific exceptions
class ServerException extends AppException {
  ServerException([super.message = 'Server error occurred']);
}

class CacheException extends AppException {
  CacheException([super.message = 'Cache error occurred']);
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Network error occurred']);
}

class AuthException extends AppException {
  AuthException(super.message, [super.code]);
}

class ValidationException extends AppException {
  ValidationException(super.message);
}

class FileException extends AppException {
  FileException(super.message);
}
