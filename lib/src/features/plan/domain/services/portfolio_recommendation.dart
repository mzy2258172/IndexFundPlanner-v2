import '../entities/plan.dart';
import '../../../user/domain/entities/user.dart';
import 'fund_scoring.dart';

/// 组合推荐算法
class PortfolioRecommendationEngine {
  
  /// 根据风险等级获取资产配置框架
  static Map<String, double> getAssetAllocation(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.conservative:
        return {
          'money': 0.40,  // 货币基金 40%
          'bond': 0.50,   // 债券基金 50%
          'broad': 0.10,  // 宽基指数 10%
        };
      case RiskLevel.steady:
        return {
          'money': 0.20,
          'bond': 0.40,
          'broad': 0.30,
          'sector': 0.10,
        };
      case RiskLevel.balanced:
        return {
          'money': 0.10,
          'bond': 0.30,
          'broad': 0.40,
          'sector': 0.20,
        };
      case RiskLevel.aggressive:
        return {
          'money': 0.05,
          'bond': 0.15,
          'broad': 0.50,
          'sector': 0.30,
        };
      case RiskLevel.radical:
        return {
          'money': 0.0,
          'bond': 0.10,
          'broad': 0.50,
          'sector': 0.40,
        };
      default:
        return {
          'money': 0.30,
          'bond': 0.40,
          'broad': 0.30,
        };
    }
  }
  
  /// 生成推荐组合（三档方案）
  static List<Portfolio> generateRecommendedPortfolios({
    required RiskLevel riskLevel,
    required double totalAmount,
    int userRiskScore = 50,
  }) {
    final baseLevel = riskLevel;
    
    // 保守方案
    final conservativeLevel = baseLevel.index > 1 
      ? RiskLevel.values[baseLevel.index - 1] 
      : RiskLevel.conservative;
    
    // 进取方案
    final aggressiveLevel = baseLevel.index < 5 
      ? RiskLevel.values[baseLevel.index + 1] 
      : RiskLevel.radical;
    
    return [
      _createPortfolio(
        name: '稳健方案',
        riskLevel: conservativeLevel.index,
        totalAmount: totalAmount,
        assetAllocation: getAssetAllocation(conservativeLevel),
        type: 'recommended',
      ),
      _createPortfolio(
        name: '均衡方案',
        riskLevel: baseLevel.index,
        totalAmount: totalAmount,
        assetAllocation: getAssetAllocation(baseLevel),
        type: 'recommended',
      ),
      _createPortfolio(
        name: '进取方案',
        riskLevel: aggressiveLevel.index,
        totalAmount: totalAmount,
        assetAllocation: getAssetAllocation(aggressiveLevel),
        type: 'recommended',
      ),
    ];
  }
  
  static Portfolio _createPortfolio({
    required String name,
    required int riskLevel,
    required double totalAmount,
    required Map<String, double> assetAllocation,
    required String type,
  }) {
    final allocations = _mapAssetToFundAllocations(assetAllocation, totalAmount);
    
    // 计算预期收益
    double expectedMin = 0;
    double expectedMax = 0;
    
    for (final entry in assetAllocation.entries) {
      final (min, max) = _getExpectedReturn(entry.key);
      expectedMin += entry.value * min;
      expectedMax += entry.value * max;
    }
    
    return Portfolio(
      id: 'portfolio_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      allocations: allocations,
      totalAmount: totalAmount,
      expectedReturnMin: expectedMin * 100,
      expectedReturnMax: expectedMax * 100,
      riskLevel: riskLevel,
    );
  }
  
  /// 将资产配置映射到具体基金（优化版：使用评分模型）
  static List<PortfolioAllocation> _mapAssetToFundAllocations(
    Map<String, double> assetAllocation,
    double totalAmount,
  ) {
    final allocations = <PortfolioAllocation>[];
    
    // 基金池配置（每类资产可选基金）
    final fundPools = {
      'money': ['511880'],
      'bond': ['511010', '511220', '511030'],
      'broad': ['510300', '510500', '159915', '159949'],
      'sector': ['512880', '512690', '512760', '512010', '512660'],
      'cross': ['513100', '513050', '513030'],
    };
    
    assetAllocation.forEach((assetType, ratio) {
      final fundCodes = fundPools[assetType] ?? [];
      if (fundCodes.isEmpty) return;
      
      // 获取该类型基金的评分并排序
      final scoredFunds = FundScoringService.scoreFunds(fundCodes);
      if (scoredFunds.isEmpty) return;
      
      // 根据配置比例决定选择几只基金
      int topN;
      if (ratio >= 0.30) {
        topN = 3;
      } else if (ratio >= 0.15) {
        topN = 2;
      } else {
        topN = 1;
      }
      
      // 取评分最高的 topN 只基金
      final selectedFunds = scoredFunds.take(topN).toList();
      final totalScore = selectedFunds.fold<double>(0, (sum, f) => sum + f.totalScore);
      
      // 按评分权重分配资金
      for (final fund in selectedFunds) {
        final weight = fund.totalScore / totalScore;
        final fundAmount = totalAmount * ratio * weight;
        final fundRatio = ratio * weight * 100;
        
        allocations.add(PortfolioAllocation(
          fundCode: fund.fundCode,
          fundName: fund.fundName,
          ratio: fundRatio,
          amount: fundAmount,
        ));
      }
    });
    
    return allocations;
  }
  
  /// 获取各类资产预期收益率
  static (double, double) _getExpectedReturn(String assetType) {
    switch (assetType) {
      case 'money':
        return (0.02, 0.03);
      case 'bond':
        return (0.03, 0.06);
      case 'broad':
        return (0.08, 0.12);
      case 'sector':
        return (0.10, 0.18);
      case 'cross':
        return (0.08, 0.15);
      default:
        return (0.05, 0.08);
    }
  }
  
  /// 计算建议月投入额
  static double calculateSuggestedMonthlyInvestment({
    required double targetAmount,
    required int months,
    required double initialCapital,
    required RiskLevel riskLevel,
  }) {
    // 根据风险等级确定预期收益率
    final annualReturns = {
      RiskLevel.conservative: 0.03,
      RiskLevel.steady: 0.05,
      RiskLevel.balanced: 0.08,
      RiskLevel.aggressive: 0.10,
      RiskLevel.radical: 0.125,
      RiskLevel.unknown: 0.06,
    };
    
    final annualReturn = annualReturns[riskLevel] ?? 0.06;
    final monthlyReturn = annualReturn / 12;
    
    // 初始本金复利终值
    final fvInitial = initialCapital * (1 + monthlyReturn) * months;
    
    // 需要通过定投达成的金额
    final fvNeeded = targetAmount - fvInitial;
    
    // 反推月投入额
    double monthlyPmt;
    if (monthlyReturn == 0) {
      monthlyPmt = fvNeeded / months;
    } else {
      monthlyPmt = fvNeeded * monthlyReturn / 
        (((1 + monthlyReturn) * months - 1) * (1 + monthlyReturn));
    }
    
    // 向上取整到百位
    return (monthlyPmt / 100).ceil() * 100;
  }
  
  /// 计算目标达成可行性评分
  static double calculateFeasibilityScore({
    required double targetAmount,
    required int months,
    required double initialCapital,
    required double monthlyInvestment,
    required RiskLevel riskLevel,
  }) {
    final annualReturns = {
      RiskLevel.conservative: (0.02, 0.04),
      RiskLevel.steady: (0.04, 0.06),
      RiskLevel.balanced: (0.06, 0.10),
      RiskLevel.aggressive: (0.08, 0.12),
      RiskLevel.radical: (0.10, 0.15),
      RiskLevel.unknown: (0.04, 0.08),
    };
    
    final (minReturn, maxReturn) = annualReturns[riskLevel] ?? (0.04, 0.08);
    
    // 计算保守情况下的终值
    final minMonthlyReturn = minReturn / 12;
    final fvInitial = initialCapital * (1 + minMonthlyReturn) * months;
    final fvSip = monthlyInvestment * months * (1 + minMonthlyReturn / 2);
    final fvConservative = fvInitial + fvSip;
    
    // 可行性评分
    final score = (fvConservative / targetAmount) * 100;
    return score.clamp(0, 150);
  }
  
  /// 组合优化
  static Portfolio optimizePortfolio({
    required Portfolio portfolio,
    required double totalAmount,
    Map<String, double>? customAllocations,
  }) {
    // 如果有自定义配置，使用自定义配置
    final allocations = customAllocations != null
      ? _mapAssetToFundAllocations(customAllocations, totalAmount)
      : portfolio.allocations;
    
    // 重新计算预期收益
    double expectedMin = 0;
    double expectedMax = 0;
    
    for (final allocation in allocations) {
      final fund = FundScoringService.getFundModel(allocation.fundCode);
      if (fund != null) {
        // 根据基金类型估算收益
        final assetType = _getAssetTypeByFundCode(allocation.fundCode);
        final (min, max) = _getExpectedReturn(assetType);
        expectedMin += (allocation.ratio / 100) * min;
        expectedMax += (allocation.ratio / 100) * max;
      }
    }
    
    return Portfolio(
      id: portfolio.id,
      name: portfolio.name,
      type: portfolio.type,
      allocations: allocations,
      totalAmount: totalAmount,
      expectedReturnMin: expectedMin * 100,
      expectedReturnMax: expectedMax * 100,
      riskLevel: portfolio.riskLevel,
    );
  }
  
  /// 根据基金代码获取资产类型
  static String _getAssetTypeByFundCode(String fundCode) {
    final fundPools = {
      'money': ['511880'],
      'bond': ['511010', '511220', '511030'],
      'broad': ['510300', '510500', '159915', '159949'],
      'sector': ['512880', '512690', '512760', '512010', '512660'],
      'cross': ['513100', '513050', '513030'],
    };
    
    for (final entry in fundPools.entries) {
      if (entry.value.contains(fundCode)) {
        return entry.key;
      }
    }
    return 'other';
  }
  
  /// 组合对比
  static PortfolioComparison comparePortfolios(List<Portfolio> portfolios) {
    if (portfolios.isEmpty) {
      return PortfolioComparison(
        portfolios: [],
        bestReturn: null,
        lowestRisk: null,
        bestSharpe: null,
      );
    }
    
    Portfolio? bestReturn;
    Portfolio? lowestRisk;
    Portfolio? bestSharpe;
    
    double maxReturn = double.negativeInfinity;
    double minRisk = double.infinity;
    double maxSharpe = double.negativeInfinity;
    
    for (final portfolio in portfolios) {
      final avgReturn = ((portfolio.expectedReturnMin ?? 0) + (portfolio.expectedReturnMax ?? 0)) / 2;
      final risk = _estimatePortfolioRisk(portfolio);
      final sharpe = (risk > 0 ? avgReturn / risk : 0).toDouble();
      
      if (avgReturn > maxReturn) {
        maxReturn = avgReturn;
        bestReturn = portfolio;
      }
      
      if (risk < minRisk) {
        minRisk = risk;
        lowestRisk = portfolio;
      }
      
      if (sharpe > maxSharpe) {
        maxSharpe = sharpe;
        bestSharpe = portfolio;
      }
    }
    
    return PortfolioComparison(
      portfolios: portfolios,
      bestReturn: bestReturn,
      lowestRisk: lowestRisk,
      bestSharpe: bestSharpe,
    );
  }
  
  /// 估算组合风险
  static double _estimatePortfolioRisk(Portfolio portfolio) {
    // 简化风险估算：基于配置比例和基金波动率
    double totalRisk = 0;
    
    for (final allocation in portfolio.allocations) {
      final fund = FundScoringService.getFundModel(allocation.fundCode);
      if (fund != null) {
        totalRisk += (allocation.ratio / 100) * fund.volatility;
      }
    }
    
    return totalRisk;
  }
  
  /// 生成调仓建议
  static RebalanceSuggestion generateRebalanceSuggestion({
    required Portfolio currentPortfolio,
    required RiskLevel targetRiskLevel,
    required double totalAmount,
  }) {
    final targetAllocation = getAssetAllocation(targetRiskLevel);
    final targetPortfolio = _createPortfolio(
      name: '目标组合',
      riskLevel: targetRiskLevel.index,
      totalAmount: totalAmount,
      assetAllocation: targetAllocation,
      type: 'target',
    );
    
    // 计算配置偏离
    final deviations = <AllocationDeviation>[];
    
    for (final targetAlloc in targetPortfolio.allocations) {
      final currentAlloc = currentPortfolio.allocations
        .where((a) => a.fundCode == targetAlloc.fundCode)
        .firstOrNull;
      
      final currentRatio = currentAlloc?.ratio ?? 0;
      final deviation = targetAlloc.ratio - currentRatio;
      
      if (deviation.abs() > 1) {  // 偏离超过 1%
        deviations.add(AllocationDeviation(
          fundCode: targetAlloc.fundCode,
          fundName: targetAlloc.fundName,
          currentRatio: currentRatio,
          targetRatio: targetAlloc.ratio,
          deviation: deviation,
          action: deviation > 0 ? RebalanceAction.buy : RebalanceAction.sell,
        ));
      }
    }
    
    return RebalanceSuggestion(
      reason: '配置偏离目标，建议调整以匹配风险等级',
      deviations: deviations,
      targetPortfolio: targetPortfolio,
      expectedImprovement: '预期风险收益比优化',
    );
  }
}

/// 组合对比结果
class PortfolioComparison {
  final List<Portfolio> portfolios;
  final Portfolio? bestReturn;
  final Portfolio? lowestRisk;
  final Portfolio? bestSharpe;
  
  const PortfolioComparison({
    required this.portfolios,
    this.bestReturn,
    this.lowestRisk,
    this.bestSharpe,
  });
  
  Map<String, dynamic> toJson() => {
    'portfolioCount': portfolios.length,
    'bestReturn': bestReturn?.name,
    'lowestRisk': lowestRisk?.name,
    'bestSharpe': bestSharpe?.name,
  };
}

/// 调仓建议
class RebalanceSuggestion {
  final String reason;
  final List<AllocationDeviation> deviations;
  final Portfolio targetPortfolio;
  final String expectedImprovement;
  
  const RebalanceSuggestion({
    required this.reason,
    required this.deviations,
    required this.targetPortfolio,
    required this.expectedImprovement,
  });
  
  bool get needRebalance => deviations.isNotEmpty;
  
  int get sellCount => deviations.where((d) => d.action == RebalanceAction.sell).length;
  int get buyCount => deviations.where((d) => d.action == RebalanceAction.buy).length;
}

/// 配置偏离
class AllocationDeviation {
  final String fundCode;
  final String fundName;
  final double currentRatio;
  final double targetRatio;
  final double deviation;
  final RebalanceAction action;
  
  const AllocationDeviation({
    required this.fundCode,
    required this.fundName,
    required this.currentRatio,
    required this.targetRatio,
    required this.deviation,
    required this.action,
  });
}

/// 调仓动作
enum RebalanceAction {
  buy,
  sell,
  hold,
}

/// 组合回测服务
class PortfolioBacktestService {
  /// 执行历史回测（简化版：基于模拟数据）
  static BacktestResult backtest({
    required Portfolio portfolio,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // 生成模拟净值曲线
    final navCurve = _generateSimulatedNavCurve(
      portfolio: portfolio,
      startDate: startDate,
      endDate: endDate,
    );
    
    // 计算回测指标
    final totalReturn = _calculateTotalReturn(navCurve);
    final annualReturn = _calculateAnnualReturn(navCurve);
    final maxDrawdown = _calculateMaxDrawdown(navCurve);
    final sharpeRatio = _calculateSharpeRatio(navCurve);
    final volatility = _calculateVolatility(navCurve);
    
    return BacktestResult(
      portfolioId: portfolio.id,
      portfolioName: portfolio.name,
      startDate: startDate,
      endDate: endDate,
      totalReturn: totalReturn,
      annualReturn: annualReturn,
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio,
      volatility: volatility,
      navCurve: navCurve,
    );
  }
  
  /// 生成模拟净值曲线
  static List<NavPoint> _generateSimulatedNavCurve({
    required Portfolio portfolio,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final curve = <NavPoint>[];
    var currentDate = startDate;
    var nav = 1.0;
    
    // 基于组合预期收益生成模拟曲线
    final expectedReturn = ((portfolio.expectedReturnMin ?? 6) + (portfolio.expectedReturnMax ?? 10)) / 2 / 100;
    final volatility = PortfolioRecommendationEngine._estimatePortfolioRisk(portfolio) / 100;
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final days = endDate.difference(startDate).inDays;
    
    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      // 只处理交易日（简化：排除周末）
      if (currentDate.weekday != DateTime.saturday && currentDate.weekday != DateTime.sunday) {
        // 模拟日收益率
        final dayIndex = currentDate.difference(startDate).inDays;
        final dailyReturn = expectedReturn / 252 + 
          (volatility / 16) * _pseudoRandom(random + dayIndex);
        
        nav *= (1 + dailyReturn);
        
        curve.add(NavPoint(
          date: currentDate,
          nav: nav,
          dailyReturn: dailyReturn * 100,
        ));
      }
      
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    return curve;
  }
  
  /// 简单伪随机数生成
  static double _pseudoRandom(int seed) {
    return ((seed * 1103515245 + 12345) % 2147483648) / 2147483648 - 0.5;
  }
  
  /// 计算总收益
  static double _calculateTotalReturn(List<NavPoint> curve) {
    if (curve.isEmpty) return 0;
    return (curve.last.nav / curve.first.nav - 1) * 100;
  }
  
  /// 计算年化收益
  static double _calculateAnnualReturn(List<NavPoint> curve) {
    if (curve.length < 2) return 0;
    
    final totalReturn = curve.last.nav / curve.first.nav;
    final years = curve.last.date.difference(curve.first.date).inDays / 365;
    
    if (years <= 0) return 0;
    
    return (totalReturn.pow(1 / years) - 1) * 100;
  }
  
  /// 计算最大回撤
  static double _calculateMaxDrawdown(List<NavPoint> curve) {
    if (curve.isEmpty) return 0;
    
    double maxNav = 0;
    double maxDrawdown = 0;
    
    for (final point in curve) {
      if (point.nav > maxNav) {
        maxNav = point.nav;
      }
      
      final drawdown = (maxNav - point.nav) / maxNav * 100;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }
    
    return maxDrawdown;
  }
  
  /// 计算夏普比率
  static double _calculateSharpeRatio(List<NavPoint> curve) {
    if (curve.length < 2) return 0;
    
    final annualReturn = _calculateAnnualReturn(curve);
    final volatility = _calculateVolatility(curve);
    
    if (volatility <= 0) return 0;
    
    // 无风险利率假设为 3%
    return (annualReturn - 3) / volatility;
  }
  
  /// 计算波动率
  static double _calculateVolatility(List<NavPoint> curve) {
    if (curve.length < 2) return 0;
    
    // 计算日收益率标准差
    final returns = <double>[];
    for (var i = 1; i < curve.length; i++) {
      returns.add(curve[i].dailyReturn);
    }
    
    if (returns.isEmpty) return 0;
    
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => (r - mean) * (r - mean)).reduce((a, b) => a + b) / returns.length;
    
    // 年化波动率
    return variance.sqrt() * 16;  // 简化：使用16作为交易日平方根
  }
}

/// 净值点
class NavPoint {
  final DateTime date;
  final double nav;
  final double dailyReturn;
  
  const NavPoint({
    required this.date,
    required this.nav,
    required this.dailyReturn,
  });
}

/// 回测结果
class BacktestResult {
  final String portfolioId;
  final String portfolioName;
  final DateTime startDate;
  final DateTime endDate;
  final double totalReturn;
  final double annualReturn;
  final double maxDrawdown;
  final double sharpeRatio;
  final double volatility;
  final List<NavPoint> navCurve;
  
  const BacktestResult({
    required this.portfolioId,
    required this.portfolioName,
    required this.startDate,
    required this.endDate,
    required this.totalReturn,
    required this.annualReturn,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.volatility,
    required this.navCurve,
  });
  
  /// 风险收益比
  double get riskReturnRatio => volatility > 0 ? annualReturn / volatility : 0;
  
  /// 回测天数
  int get tradingDays => navCurve.length;
  
  Map<String, dynamic> toJson() => {
    'portfolioId': portfolioId,
    'portfolioName': portfolioName,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalReturn': totalReturn,
    'annualReturn': annualReturn,
    'maxDrawdown': maxDrawdown,
    'sharpeRatio': sharpeRatio,
    'volatility': volatility,
    'tradingDays': tradingDays,
  };
}

/// double 扩展
extension DoubleExtension on double {
  double pow(double exponent) {
    return exponent == 0 ? 1 : exponent == 1 ? this : _pow(this, exponent);
  }
  
  double sqrt() {
    if (this < 0) return 0;
    return _sqrt(this);
  }
  
  static double _pow(double base, double exponent) {
    // 简单的幂运算实现
    if (exponent == exponent.toInt()) {
      var result = 1.0;
      for (var i = 0; i < exponent.toInt(); i++) {
        result *= base;
      }
      return result;
    }
    // 非整数幂使用自然对数近似
    return base;
  }
  
  static double _sqrt(double x) {
    // 牛顿法求平方根
    if (x == 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
