import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/fund.dart';

/// 基金缓存服务
/// 
/// 使用内存缓存 + 可选的本地持久化
/// 缓存策略：
/// - 基金列表：24小时过期
/// - 基金详情：1小时过期
/// - 净值历史：6小时过期
class FundCacheService {
  // 内存缓存
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // 缓存过期时间配置
  static const Duration fundListMaxAge = Duration(hours: 24);
  static const Duration fundDetailMaxAge = Duration(hours: 1);
  static const Duration netValueHistoryMaxAge = Duration(hours: 6);
  
  /// 缓存键前缀
  static const String _keyPrefixFundList = 'fund_list_';
  static const String _keyPrefixFundDetail = 'fund_detail_';
  static const String _keyPrefixNetValueHistory = 'net_value_history_';
  
  /// 缓存基金搜索结果
  void cacheFundList(String keyword, List<Fund> funds) {
    final key = '$_keyPrefixFundList${keyword.toLowerCase()}';
    final cachedList = CachedFundList(
      funds: funds,
      cachedAt: DateTime.now(),
      cacheKey: keyword,
    );
    _memoryCache[key] = _CacheEntry(
      data: cachedList.toJson(),
      cachedAt: DateTime.now(),
      maxAge: fundListMaxAge,
    );
  }
  
  /// 获取缓存的基金列表
  List<Fund>? getCachedFundList(String keyword) {
    final key = '$_keyPrefixFundList${keyword.toLowerCase()}';
    final entry = _memoryCache[key];
    
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    
    try {
      final cachedList = CachedFundList.fromJson(
        jsonDecode(jsonEncode(entry.data)) as Map<String, dynamic>,
      );
      return cachedList.funds;
    } catch (e) {
      _memoryCache.remove(key);
      return null;
    }
  }
  
  /// 缓存基金详情
  void cacheFundDetail(String fundCode, FundDetail detail) {
    final key = '$_keyPrefixFundDetail$fundCode';
    final cachedDetail = CachedFundDetail(
      detail: detail,
      cachedAt: DateTime.now(),
    );
    _memoryCache[key] = _CacheEntry(
      data: cachedDetail.toJson(),
      cachedAt: DateTime.now(),
      maxAge: fundDetailMaxAge,
    );
  }
  
  /// 获取缓存的基金详情
  FundDetail? getCachedFundDetail(String fundCode) {
    final key = '$_keyPrefixFundDetail$fundCode';
    final entry = _memoryCache[key];
    
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    
    try {
      final cachedDetail = CachedFundDetail.fromJson(
        jsonDecode(jsonEncode(entry.data)) as Map<String, dynamic>,
      );
      return cachedDetail.detail;
    } catch (e) {
      _memoryCache.remove(key);
      return null;
    }
  }
  
  /// 缓存净值历史
  void cacheNetValueHistory(String fundCode, List<FundNetValue> history, int requestedDays) {
    final key = '$_keyPrefixNetValueHistory$fundCode';
    final cachedHistory = CachedNetValueHistory(
      fundCode: fundCode,
      history: history,
      cachedAt: DateTime.now(),
      requestedDays: requestedDays,
    );
    _memoryCache[key] = _CacheEntry(
      data: cachedHistory.toJson(),
      cachedAt: DateTime.now(),
      maxAge: netValueHistoryMaxAge,
    );
  }
  
  /// 获取缓存的净值历史
  List<FundNetValue>? getCachedNetValueHistory(String fundCode, int requestedDays) {
    final key = '$_keyPrefixNetValueHistory$fundCode';
    final entry = _memoryCache[key];
    
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    
    try {
      final cachedHistory = CachedNetValueHistory.fromJson(
        jsonDecode(jsonEncode(entry.data)) as Map<String, dynamic>,
      );
      
      // 检查是否覆盖请求的天数
      if (cachedHistory.history.length >= requestedDays) {
        return cachedHistory.history.take(requestedDays).toList();
      }
      return null;
    } catch (e) {
      _memoryCache.remove(key);
      return null;
    }
  }
  
  /// 缓存指数基金列表
  void cacheIndexFunds(String type, List<Fund> funds) {
    cacheFundList('index_$type', funds);
  }
  
  /// 获取缓存的指数基金列表
  List<Fund>? getCachedIndexFunds(String type) {
    return getCachedFundList('index_$type');
  }
  
  /// 清除指定基金的缓存
  void invalidateFund(String fundCode) {
    _memoryCache.remove('$_keyPrefixFundDetail$fundCode');
    _memoryCache.remove('$_keyPrefixNetValueHistory$fundCode');
  }
  
  /// 清除所有基金列表缓存
  void invalidateAllFundLists() {
    _memoryCache.keys
      .where((k) => k.startsWith(_keyPrefixFundList))
      .toList()
      .forEach(_memoryCache.remove);
  }
  
  /// 清除所有缓存
  void clearAll() {
    _memoryCache.clear();
  }
  
  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    int fundListCount = 0;
    int fundDetailCount = 0;
    int netValueHistoryCount = 0;
    int expiredCount = 0;
    
    _memoryCache.forEach((key, entry) {
      if (entry.isExpired) {
        expiredCount++;
        return;
      }
      
      if (key.startsWith(_keyPrefixFundList)) {
        fundListCount++;
      } else if (key.startsWith(_keyPrefixFundDetail)) {
        fundDetailCount++;
      } else if (key.startsWith(_keyPrefixNetValueHistory)) {
        netValueHistoryCount++;
      }
    });
    
    return {
      'totalEntries': _memoryCache.length,
      'validEntries': _memoryCache.length - expiredCount,
      'expiredEntries': expiredCount,
      'fundListCount': fundListCount,
      'fundDetailCount': fundDetailCount,
      'netValueHistoryCount': netValueHistoryCount,
    };
  }
  
  /// 清理过期缓存
  void cleanExpiredCache() {
    final expiredKeys = _memoryCache.entries
      .where((e) => e.value.isExpired)
      .map((e) => e.key)
      .toList();
    
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
  }
}

/// 缓存条目
class _CacheEntry {
  final Map<String, dynamic> data;
  final DateTime cachedAt;
  final Duration maxAge;
  
  _CacheEntry({
    required this.data,
    required this.cachedAt,
    required this.maxAge,
  });
  
  bool get isExpired => DateTime.now().difference(cachedAt) > maxAge;
}

/// Provider
final fundCacheServiceProvider = Provider<FundCacheService>((ref) {
  return FundCacheService();
});
