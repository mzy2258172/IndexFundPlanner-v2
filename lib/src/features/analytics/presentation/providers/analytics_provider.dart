import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics.dart';
import '../../../portfolio/presentation/providers/portfolio_provider.dart';
import '../../../portfolio/domain/entities/portfolio.dart';

/// 分析状态
sealed class AnalyticsState {
  const AnalyticsState();
}

class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsReport report;
  const AnalyticsLoaded(this.report);
}

class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
}

/// 分析报告 Provider
final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  return AnalyticsNotifier(ref);
});

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final Ref _ref;
  
  AnalyticsNotifier(this._ref) : super(const AnalyticsInitial());
  
  /// 加载分析报告
  Future<void> loadAnalytics(String portfolioId) async {
    state = const AnalyticsLoading();
    try {
      final portfolioAsync = await _ref.read(portfolioDetailProvider(portfolioId).future);
      
      if (portfolioAsync == null) {
        state = const AnalyticsError('投资组合不存在');
        return;
      }
      
      final report = _generateReport(portfolioAsync);
      state = AnalyticsLoaded(report);
    } catch (e) {
      state = AnalyticsError(e.toString());
    }
  }
  
  /// 生成分析报告
  AnalyticsReport _generateReport(Portfolio portfolio) {
    final items = portfolio.items;
    
    if (items.isEmpty) {
      return AnalyticsReport(
        portfolioId: portfolio.id,
        generatedAt: DateTime.now(),
        totalReturn: 0,
        annualizedReturn: 0,
        maxDrawdown: 0,
        sharpeRatio: 0,
        allocations: const [],
      );
    }
    
    // 计算总收益
    final totalReturn = portfolio.totalReturnRate;
    
    // 计算年化收益（简化算法）
    final daysSinceFirstPurchase = items.isEmpty 
        ? 1 
        : DateTime.now().difference(items.map((e) => e.purchaseDate).reduce((a, b) => a.isBefore(b) ? a : b)).inDays;
    final years = (daysSinceFirstPurchase / 365).clamp(0.1, 10);
    final annualizedReturn = (totalReturn > 0) 
        ? (pow(1 + totalReturn, 1 / years) - 1)
        : totalReturn;
    
    // 计算最大回撤（简化算法，基于持仓数据估算）
    final maxDrawdown = _calculateMaxDrawdown(items);
    
    // 计算夏普比率（简化算法）
    final sharpeRatio = _calculateSharpeRatio(totalReturn, items);
    
    // 计算资产配置
    final allocations = _calculateAllocations(items, portfolio.totalValue);
    
    return AnalyticsReport(
      portfolioId: portfolio.id,
      generatedAt: DateTime.now(),
      totalReturn: totalReturn,
      annualizedReturn: annualizedReturn,
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio,
      allocations: allocations,
    );
  }
  
  double _calculateMaxDrawdown(List<PortfolioItem> items) {
    if (items.isEmpty) return 0;
    
    double maxDrawdown = 0;
    for (final item in items) {
      // 简化：假设最大回撤为收益率为负时的最大损失比例
      if (item.returnRate < 0) {
        maxDrawdown = max(maxDrawdown, item.returnRate.abs());
      }
    }
    return maxDrawdown;
  }
  
  double _calculateSharpeRatio(double totalReturn, List<PortfolioItem> items) {
    if (items.isEmpty) return 0;
    
    // 简化计算：假设无风险利率为 3%
    const riskFreeRate = 0.03;
    
    // 简化波动率估算（基于持仓收益率差异）
    if (items.length == 1) {
      return (totalReturn - riskFreeRate) / 0.15; // 假设波动率 15%
    }
    
    final returns = items.map((e) => e.returnRate).toList();
    final avgReturn = returns.reduce((a, b) => a + b) / returns.length;
    
    double variance = 0;
    for (final r in returns) {
      variance += pow(r - avgReturn, 2);
    }
    final stdDev = sqrt(variance / returns.length);
    
    if (stdDev == 0) return 0;
    return (totalReturn - riskFreeRate) / stdDev;
  }
  
  List<AssetAllocation> _calculateAllocations(List<PortfolioItem> items, double totalValue) {
    if (totalValue <= 0) return [];
    
    final Map<String, double> typeValues = {};
    for (final item in items) {
      final type = _getFundType(item.fundCode);
      typeValues[type] = (typeValues[type] ?? 0) + item.currentValue;
    }
    
    return typeValues.entries.map((e) => AssetAllocation(
      assetName: e.key,
      assetType: e.key,
      percentage: e.value / totalValue,
      amount: e.value,
    )).toList();
  }
  
  String _getFundType(String code) {
    if (code.startsWith('51')) {
      if (code.contains('300') || code.contains('500') || code.contains('800')) {
        return '宽基指数';
      }
    }
    if (code.startsWith('159')) {
      return '行业指数';
    }
    if (code.startsWith('00')) {
      return '主动基金';
    }
    return '其他';
  }
}

// 数学辅助函数
double pow(double base, double exponent) {
  return base.toDouble().pow(exponent);
}

double sqrt(double value) {
  return value.toDouble().sqrt();
}

double max(double a, double b) {
  return a > b ? a : b;
}

// 扩展方法
extension DoubleExtension on double {
  double pow(double exponent) {
    if (exponent == 0) return 1;
    if (exponent == 1) return this;
    if (exponent == 2) return this * this;
    
    // 简化的幂运算实现
    double result = 1;
    double base = this;
    double exp = exponent.abs();
    
    while (exp > 0) {
      if (exp >= 1) {
        result *= base;
        exp -= 1;
      } else {
        // 对于小数指数，使用近似
        result *= (1 + (base - 1) * exp);
        break;
      }
    }
    
    return exponent < 0 ? 1 / result : result;
  }
  
  double sqrt() {
    if (this < 0) return 0;
    if (this == 0) return 0;
    
    // 牛顿法求平方根
    double x = this;
    double y = (x + 1) / 2;
    while ((y - x).abs() > 0.00001) {
      x = y;
      y = (x + this / x) / 2;
    }
    return y;
  }
}
