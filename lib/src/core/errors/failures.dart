/// 应用错误基类
abstract class Failure {
  final String message;
  final int? code;
  
  const Failure(this.message, {this.code});
}

/// 网络错误
class NetworkFailure extends Failure {
  const NetworkFailure(String message, {int? code}) : super(message, code: code);
}

/// 服务器错误
class ServerFailure extends Failure {
  const ServerFailure(String message, {int? code}) : super(message, code: code);
}

/// 本地存储错误
class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

/// 未知错误
class UnknownFailure extends Failure {
  const UnknownFailure(String message) : super(message);
}
