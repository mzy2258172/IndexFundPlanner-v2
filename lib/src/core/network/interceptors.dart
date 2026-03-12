import 'package:dio/dio.dart';

/// 重试拦截器
/// 
/// 自动重试失败的请求，支持配置：
/// - 重试次数
/// - 重试间隔
/// - 可重试的错误类型
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration retryInterval;
  final Set<DioExceptionType> retryableErrors;
  
  RetryInterceptor({
    this.maxRetries = 3,
    this.retryInterval = const Duration(seconds: 1),
    this.retryableErrors = const {
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.connectionError,
    },
  });
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 检查是否可以重试
    if (!_shouldRetry(err)) {
      return handler.next(err);
    }
    
    // 获取已重试次数
    final retryCount = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    
    // 检查是否超过最大重试次数
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }
    
    // 更新重试次数
    err.requestOptions.extra['retryCount'] = retryCount + 1;
    
    // 等待后重试
    await Future.delayed(retryInterval * retryCount);
    
    try {
      final response = await _retry(err.requestOptions);
      return handler.resolve(response);
    } catch (e) {
      if (e is DioException) {
        return handler.next(e);
      }
      return handler.next(err);
    }
  }
  
  bool _shouldRetry(DioException err) {
    return retryableErrors.contains(err.type);
  }
  
  Future<Response<dynamic>> _retry(RequestOptions requestOptions) async {
    final dio = Dio(BaseOptions(
      connectTimeout: requestOptions.connectTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      sendTimeout: requestOptions.sendTimeout,
    ));
    
    return dio.fetch(requestOptions);
  }
}

/// 缓存拦截器
/// 
/// 为GET请求添加缓存控制头
class CacheInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // 为天天基金API添加Referer
    if (options.uri.host.contains('eastmoney.com')) {
      options.headers['Referer'] = 'https://fund.eastmoney.com/';
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // 可以在这里处理响应缓存逻辑
    handler.next(response);
  }
}

/// 日志拦截器（简化版）
class SimpleLogInterceptor extends Interceptor {
  final bool enabled;
  
  SimpleLogInterceptor({this.enabled = true});
  
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) {
      print('[API] ${options.method} ${options.uri}');
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      print('[API ERROR] ${err.type}: ${err.message}');
    }
    handler.next(err);
  }
}
