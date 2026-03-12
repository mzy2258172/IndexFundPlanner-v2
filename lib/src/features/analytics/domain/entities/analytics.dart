/// 投资分析报告
class AnalyticsReport {
  final String portfolioId;
  final DateTime generatedAt;
  final double totalReturn;
  final double annualizedReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final List<AssetAllocation> allocations;
  
  const AnalyticsReport({
    required this.portfolioId,
    required this.generatedAt,
    required this.totalReturn,
    required this.annualizedReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.allocations,
  });
}

/// 资产配置
class AssetAllocation {
  final String assetName;
  final String assetType;
  final double percentage;
  final double amount;
  
  const AssetAllocation({
    required this.assetName,
    required this.assetType,
    required this.percentage,
    required this.amount,
  });
}

/// 收益趋势数据
class ReturnTrend {
  final DateTime date;
  final double returnRate;
  final double cumulativeReturn;
  
  const ReturnTrend({
    required this.date,
    required this.returnRate,
    required this.cumulativeReturn,
  });
}
