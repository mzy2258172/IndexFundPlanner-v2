class AppException implements Exception {
  final String message;
  final int? code;
  
  const AppException(this.message, {this.code});
  
  @override
  String toString() => 'AppException: $message (code: $code)';
}

class NetworkException extends AppException {
  const NetworkException(String message, {int? code}) : super(message, code: code);
}

class ServerException extends AppException {
  const ServerException(String message, {int? code}) : super(message, code: code);
}

class CacheException extends AppException {
  const CacheException(String message) : super(message);
}
