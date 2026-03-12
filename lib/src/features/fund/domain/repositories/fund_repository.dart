import '../entities/fund.dart';

/// 基金数据仓储接口
abstract class FundRepository {
  /// 搜索基金
  /// 
  /// [keyword] 搜索关键词（基金代码或名称）
  /// [useCache] 是否使用缓存（默认true）
  Future<List<Fund>> searchFunds(String keyword, {bool useCache = true});
  
  /// 根据基金代码获取基金信息
  /// 
  /// [code] 基金代码
  /// [useCache] 是否使用缓存（默认true）
  Future<Fund?> getFundByCode(String code, {bool useCache = true});
  
  /// 获取基金详情
  /// 
  /// [code] 基金代码
  /// [useCache] 是否使用缓存（默认true）
  Future<FundDetail?> getFundDetail(String code, {bool useCache = true});
  
  /// 获取基金净值历史
  /// 
  /// [code] 基金代码
  /// [days] 天数
  /// [useCache] 是否使用缓存（默认true）
  Future<List<FundNetValue>> getFundNetValueHistory(
    String code, {
    int days = 30,
    bool useCache = true,
  });
  
  /// 获取指数基金列表
  /// 
  /// [type] 类型：broad(宽基), sector(行业), theme(主题), all(全部)
  /// [sort] 排序字段
  /// [useCache] 是否使用缓存（默认true）
  Future<List<Fund>> getIndexFunds({
    String type = 'all',
    String sort = 'rzdf',
    bool useCache = true,
  });
  
  /// 获取热门指数基金
  Future<List<Fund>> getHotIndexFunds({bool useCache = true});
  
  /// 清除指定基金的缓存
  void invalidateFund(String fundCode);
  
  /// 清除所有缓存
  void invalidateAllCache();
}
