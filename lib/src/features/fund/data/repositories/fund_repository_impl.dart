import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../domain/entities/fund.dart';
import '../domain/repositories/fund_repository.dart';
import 'services/eastmoney_service.dart';
import 'services/fund_cache_service.dart';

/// 基金数据仓储实现
class FundRepositoryImpl implements FundRepository {
  final EastMoneyService _eastMoneyService;
  final FundCacheService _cacheService;
  
  FundRepositoryImpl({
    required EastMoneyService eastMoneyService,
    required FundCacheService cacheService,
  })  : _eastMoneyService = eastMoneyService,
        _cacheService = cacheService;
  
  @override
  Future<List<Fund>> searchFunds(String keyword, {bool useCache = true}) async {
    if (keyword.trim().isEmpty) {
      // 返回热门指数基金
      return getHotIndexFunds(useCache: useCache);
    }
    
    // 尝试从缓存获取
    if (useCache) {
      final cached = _cacheService.getCachedFundList(keyword);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }
    
    // 从API获取
    try {
      final funds = await _eastMoneyService.searchFunds(keyword: keyword);
      
      // 缓存结果
      if (funds.isNotEmpty) {
        _cacheService.cacheFundList(keyword, funds);
      }
      
      return funds;
    } catch (e) {
      // 网络错误时尝试返回缓存（即使过期）
      final cached = _cacheService.getCachedFundList(keyword);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
  
  @override
  Future<Fund?> getFundByCode(String code, {bool useCache = true}) async {
    final detail = await getFundDetail(code, useCache: useCache);
    return detail?.fund;
  }
  
  @override
  Future<FundDetail?> getFundDetail(String code, {bool useCache = true}) async {
    // 尝试从缓存获取
    if (useCache) {
      final cached = _cacheService.getCachedFundDetail(code);
      if (cached != null) {
        return cached;
      }
    }
    
    // 从API获取
    try {
      final detail = await _eastMoneyService.getFundDetail(code);
      
      // 缓存结果
      if (detail != null) {
        _cacheService.cacheFundDetail(code, detail);
      }
      
      return detail;
    } catch (e) {
      // 网络错误时尝试返回缓存（即使过期）
      final cached = _cacheService.getCachedFundDetail(code);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
  
  @override
  Future<List<FundNetValue>> getFundNetValueHistory(
    String code, {
    int days = 30,
    bool useCache = true,
  }) async {
    // 尝试从缓存获取
    if (useCache) {
      final cached = _cacheService.getCachedNetValueHistory(code, days);
      if (cached != null) {
        return cached;
      }
    }
    
    // 从API获取
    try {
      final history = await _eastMoneyService.getNetValueHistory(code, days: days);
      
      // 缓存结果
      if (history.isNotEmpty) {
        _cacheService.cacheNetValueHistory(code, history, days);
      }
      
      return history;
    } catch (e) {
      // 网络错误时尝试返回缓存
      final cached = _cacheService.getCachedNetValueHistory(code, days);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
  
  @override
  Future<List<Fund>> getIndexFunds({
    String type = 'all',
    String sort = 'rzdf',
    bool useCache = true,
  }) async {
    final cacheKey = '${type}_$sort';
    
    // 尝试从缓存获取
    if (useCache) {
      final cached = _cacheService.getCachedIndexFunds(cacheKey);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }
    
    // 从API获取
    try {
      final funds = await _eastMoneyService.getIndexFunds(
        type: type,
        sort: sort,
      );
      
      // 缓存结果
      if (funds.isNotEmpty) {
        _cacheService.cacheIndexFunds(cacheKey, funds);
      }
      
      return funds;
    } catch (e) {
      // 网络错误时尝试返回缓存
      final cached = _cacheService.getCachedIndexFunds(cacheKey);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
  
  @override
  Future<List<Fund>> getHotIndexFunds({bool useCache = true}) async {
    return getIndexFunds(type: 'all', sort: 'rzdf', useCache: useCache);
  }
  
  @override
  void invalidateFund(String fundCode) {
    _cacheService.invalidateFund(fundCode);
  }
  
  @override
  void invalidateAllCache() {
    _cacheService.clearAll();
  }
}

// ==================== Providers ====================

/// 天天基金服务 Provider
final eastMoneyServiceProvider = Provider<EastMoneyService>((ref) {
  final dio = ref.watch(dioProvider);
  return EastMoneyService(dio);
});

/// 基金仓储 Provider
final fundRepositoryProvider = Provider<FundRepository>((ref) {
  final eastMoneyService = ref.watch(eastMoneyServiceProvider);
  final cacheService = ref.watch(fundCacheServiceProvider);
  
  return FundRepositoryImpl(
    eastMoneyService: eastMoneyService,
    cacheService: cacheService,
  );
});
