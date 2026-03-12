import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'interceptors.dart';

/// Dio 客户端 Provider
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json, text/plain, */*',
      },
    ),
  );
  
  // 添加拦截器
  dio.interceptors.addAll([
    // 重试拦截器
    RetryInterceptor(
      maxRetries: 3,
      retryInterval: const Duration(milliseconds: 500),
    ),
    // 缓存拦截器
    CacheInterceptor(),
    // 日志拦截器（生产环境可禁用）
    SimpleLogInterceptor(enabled: true),
  ]);
  
  return dio;
});
