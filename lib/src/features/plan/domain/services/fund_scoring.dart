/// 基金评分模型
/// 
/// 基于多维度评分体系对基金进行综合评估
class FundScoringModel {
  /// 基金评分数据
  final String fundCode;
  final String fundName;
  
  // 近期收益数据
  final double return1m;   // 近1月收益率
  final double return3m;   // 近3月收益率
  final double return1y;   // 近1年收益率
  final double return3y;   // 近3年收益率
  
  // 风险指标
  final double maxDrawdown;  // 最大回撤
  final double volatility;   // 波动率
  final double sharpeRatio;  // 夏普比率
  
  // 跟踪指标
  final double trackingError; // 跟踪误差
  
  // 费率
  final double managementFee; // 管理费率
  final double custodyFee;    // 托管费率
  
  // 规模
  final double fundSize;      // 基金规模（亿元）
  
  // 同类排名百分位
  final double rankPercentile; // 同类排名百分位
  
  const FundScoringModel({
    required this.fundCode,
    required this.fundName,
    this.return1m = 0,
    this.return3m = 0,
    this.return1y = 0,
    this.return3y = 0,
    this.maxDrawdown = 0,
    this.volatility = 0,
    this.sharpeRatio = 0,
    this.trackingError = 0,
    this.managementFee = 0,
    this.custodyFee = 0,
    this.fundSize = 0,
    this.rankPercentile = 50,
  });
  
  /// 计算综合评分（0-100分）
  FundScoreResult calculateScore({String period = '3y'}) {
    // 维度1: 收益能力（40分）
    final returnScore = _calculateReturnScore(period);
    
    // 维度2: 风险控制（30分）
    final riskScore = _calculateRiskScore();
    
    // 维度3: 跟踪效果（15分）
    final trackingScore = _calculateTrackingScore();
    
    // 维度4: 费率优势（10分）
    final feeScore = _calculateFeeScore();
    
    // 维度5: 规模流动性（5分）
    final liquidityScore = _calculateLiquidityScore();
    
    // 加权总分
    final totalScore = 
      returnScore * 0.40 + 
      riskScore * 0.30 + 
      trackingScore * 0.15 + 
      feeScore * 0.10 + 
      liquidityScore * 0.05;
    
    return FundScoreResult(
      fundCode: fundCode,
      fundName: fundName,
      totalScore: totalScore,
      returnScore: returnScore,
      riskScore: riskScore,
      trackingScore: trackingScore,
      feeScore: feeScore,
      liquidityScore: liquidityScore,
      rating: _getRating(totalScore),
    );
  }
  
  /// 收益评分（0-40分）
  double _calculateReturnScore(String period) {
    // 选择对应周期的收益率
    double periodReturn;
    switch (period) {
      case '1m':
        periodReturn = return1m;
        break;
      case '3m':
        periodReturn = return3m;
        break;
      case '1y':
        periodReturn = return1y;
        break;
      case '3y':
      default:
        periodReturn = return3y;
    }
    
    // 基于同类排名百分位评分
    if (rankPercentile <= 10) {
      return 40;  // 同类前 10%
    } else if (rankPercentile <= 30) {
      return 32;  // 同类前 30%
    } else if (rankPercentile <= 50) {
      return 24;  // 同类前 50%
    } else if (rankPercentile <= 70) {
      return 16;  // 同类前 70%
    } else {
      return 8;   // 其他
    }
  }
  
  /// 风险评分（0-30分）
  double _calculateRiskScore() {
    // 最大回撤评分（越小越好，满分15分）
    double drawdownScore;
    if (maxDrawdown <= 10) {
      drawdownScore = 15;
    } else if (maxDrawdown <= 15) {
      drawdownScore = 12;
    } else if (maxDrawdown <= 20) {
      drawdownScore = 10;
    } else if (maxDrawdown <= 30) {
      drawdownScore = 7;
    } else {
      drawdownScore = 4;
    }
    
    // 波动率评分（越小越好，满分15分）
    double volatilityScore;
    if (volatility <= 15) {
      volatilityScore = 15;
    } else if (volatility <= 20) {
      volatilityScore = 12;
    } else if (volatility <= 25) {
      volatilityScore = 10;
    } else if (volatility <= 35) {
      volatilityScore = 7;
    } else {
      volatilityScore = 4;
    }
    
    return drawdownScore + volatilityScore;
  }
  
  /// 跟踪误差评分（0-15分）
  double _calculateTrackingScore() {
    // 跟踪误差越小越好
    if (trackingError <= 0.5) {
      return 15;
    } else if (trackingError <= 1.0) {
      return 12;
    } else if (trackingError <= 1.5) {
      return 9;
    } else if (trackingError <= 2.0) {
      return 6;
    } else {
      return 3;
    }
  }
  
  /// 费率评分（0-10分）
  double _calculateFeeScore() {
    final totalFee = managementFee + custodyFee;
    
    if (totalFee <= 0.3) {
      return 10;
    } else if (totalFee <= 0.5) {
      return 8;
    } else if (totalFee <= 0.7) {
      return 6;
    } else if (totalFee <= 1.0) {
      return 4;
    } else {
      return 2;
    }
  }
  
  /// 流动性评分（0-5分）
  double _calculateLiquidityScore() {
    if (fundSize >= 100) {
      return 5;
    } else if (fundSize >= 50) {
      return 4;
    } else if (fundSize >= 20) {
      return 3;
    } else if (fundSize >= 5) {
      return 2;
    } else {
      return 1;
    }
  }
  
  /// 获取评级（1-5星）
  String _getRating(double score) {
    if (score >= 80) return '★★★★★';
    if (score >= 70) return '★★★★☆';
    if (score >= 60) return '★★★☆☆';
    if (score >= 50) return '★★☆☆☆';
    return '★☆☆☆☆';
  }
}

/// 基金评分结果
class FundScoreResult {
  final String fundCode;
  final String fundName;
  final double totalScore;
  final double returnScore;
  final double riskScore;
  final double trackingScore;
  final double feeScore;
  final double liquidityScore;
  final String rating;
  
  const FundScoreResult({
    required this.fundCode,
    required this.fundName,
    required this.totalScore,
    required this.returnScore,
    required this.riskScore,
    required this.trackingScore,
    required this.feeScore,
    required this.liquidityScore,
    required this.rating,
  });
  
  /// 是否推荐
  bool get isRecommended => totalScore >= 60;
  
  /// 评分等级
  String get scoreLevel {
    if (totalScore >= 80) return '优秀';
    if (totalScore >= 70) return '良好';
    if (totalScore >= 60) return '中等';
    if (totalScore >= 50) return '一般';
    return '较差';
  }
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'fundName': fundName,
    'totalScore': totalScore,
    'returnScore': returnScore,
    'riskScore': riskScore,
    'trackingScore': trackingScore,
    'feeScore': feeScore,
    'liquidityScore': liquidityScore,
    'rating': rating,
    'isRecommended': isRecommended,
    'scoreLevel': scoreLevel,
  };
}

/// 基金评分服务
class FundScoringService {
  /// 基金数据模拟（实际应用中应从数据源获取）
  static final Map<String, FundScoringModel> _fundDatabase = {
    // 宽基指数
    '510300': FundScoringModel(
      fundCode: '510300',
      fundName: '沪深300ETF',
      return1y: 12.56,
      return3y: 28.34,
      maxDrawdown: 18.5,
      volatility: 22.3,
      sharpeRatio: 0.85,
      trackingError: 0.35,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 156.32,
      rankPercentile: 25,
    ),
    '510500': FundScoringModel(
      fundCode: '510500',
      fundName: '中证500ETF',
      return1y: 15.23,
      return3y: 32.11,
      maxDrawdown: 22.8,
      volatility: 25.6,
      sharpeRatio: 0.92,
      trackingError: 0.42,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 98.45,
      rankPercentile: 18,
    ),
    '159915': FundScoringModel(
      fundCode: '159915',
      fundName: '创业板ETF',
      return1y: 18.45,
      return3y: 45.67,
      maxDrawdown: 28.3,
      volatility: 32.5,
      sharpeRatio: 1.05,
      trackingError: 0.55,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 85.23,
      rankPercentile: 12,
    ),
    '159949': FundScoringModel(
      fundCode: '159949',
      fundName: '创业板50ETF',
      return1y: 20.12,
      return3y: 52.34,
      maxDrawdown: 32.5,
      volatility: 35.8,
      sharpeRatio: 1.12,
      trackingError: 0.65,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 45.67,
      rankPercentile: 8,
    ),
    
    // 行业指数
    '512880': FundScoringModel(
      fundCode: '512880',
      fundName: '证券ETF',
      return1y: 25.34,
      return3y: 38.56,
      maxDrawdown: 35.2,
      volatility: 38.5,
      sharpeRatio: 0.78,
      trackingError: 0.48,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 68.90,
      rankPercentile: 22,
    ),
    '512690': FundScoringModel(
      fundCode: '512690',
      fundName: '酒ETF',
      return1y: 22.15,
      return3y: 48.23,
      maxDrawdown: 28.6,
      volatility: 30.2,
      sharpeRatio: 1.15,
      trackingError: 0.52,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 72.34,
      rankPercentile: 15,
    ),
    '512760': FundScoringModel(
      fundCode: '512760',
      fundName: '半导体ETF',
      return1y: 35.67,
      return3y: 62.45,
      maxDrawdown: 38.5,
      volatility: 42.3,
      sharpeRatio: 1.25,
      trackingError: 0.68,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 58.90,
      rankPercentile: 5,
    ),
    '512010': FundScoringModel(
      fundCode: '512010',
      fundName: '医药ETF',
      return1y: 8.45,
      return3y: 25.67,
      maxDrawdown: 25.8,
      volatility: 28.5,
      sharpeRatio: 0.68,
      trackingError: 0.45,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 82.34,
      rankPercentile: 35,
    ),
    '512660': FundScoringModel(
      fundCode: '512660',
      fundName: '军工ETF',
      return1y: 15.78,
      return3y: 42.15,
      maxDrawdown: 32.4,
      volatility: 35.6,
      sharpeRatio: 0.95,
      trackingError: 0.58,
      managementFee: 0.50,
      custodyFee: 0.10,
      fundSize: 48.67,
      rankPercentile: 18,
    ),
    
    // 债券基金
    '511010': FundScoringModel(
      fundCode: '511010',
      fundName: '国债ETF',
      return1y: 3.85,
      return3y: 12.56,
      maxDrawdown: 3.2,
      volatility: 4.5,
      sharpeRatio: 0.52,
      trackingError: 0.15,
      managementFee: 0.30,
      custodyFee: 0.10,
      fundSize: 125.67,
      rankPercentile: 30,
    ),
    '511220': FundScoringModel(
      fundCode: '511220',
      fundName: '城投ETF',
      return1y: 4.25,
      return3y: 14.23,
      maxDrawdown: 4.8,
      volatility: 5.2,
      sharpeRatio: 0.58,
      trackingError: 0.18,
      managementFee: 0.30,
      custodyFee: 0.10,
      fundSize: 68.45,
      rankPercentile: 25,
    ),
    '511030': FundScoringModel(
      fundCode: '511030',
      fundName: '公司债ETF',
      return1y: 4.56,
      return3y: 15.67,
      maxDrawdown: 5.2,
      volatility: 5.8,
      sharpeRatio: 0.62,
      trackingError: 0.20,
      managementFee: 0.30,
      custodyFee: 0.10,
      fundSize: 45.23,
      rankPercentile: 28,
    ),
    
    // 货币基金
    '511880': FundScoringModel(
      fundCode: '511880',
      fundName: '货币ETF',
      return1y: 2.15,
      return3y: 6.85,
      maxDrawdown: 0.05,
      volatility: 0.2,
      sharpeRatio: 0.85,
      trackingError: 0.02,
      managementFee: 0.15,
      custodyFee: 0.05,
      fundSize: 892.34,
      rankPercentile: 20,
    ),
    
    // 跨境指数
    '513100': FundScoringModel(
      fundCode: '513100',
      fundName: '纳指ETF',
      return1y: 28.45,
      return3y: 55.67,
      maxDrawdown: 25.8,
      volatility: 28.5,
      sharpeRatio: 1.35,
      trackingError: 0.85,
      managementFee: 0.80,
      custodyFee: 0.20,
      fundSize: 125.67,
      rankPercentile: 8,
    ),
    '513050': FundScoringModel(
      fundCode: '513050',
      fundName: '中概互联ETF',
      return1y: -5.23,
      return3y: 15.45,
      maxDrawdown: 45.6,
      volatility: 38.5,
      sharpeRatio: 0.35,
      trackingError: 1.25,
      managementFee: 0.80,
      custodyFee: 0.20,
      fundSize: 68.90,
      rankPercentile: 65,
    ),
    '513030': FundScoringModel(
      fundCode: '513030',
      fundName: '恒生ETF',
      return1y: 8.56,
      return3y: 18.23,
      maxDrawdown: 32.5,
      volatility: 30.5,
      sharpeRatio: 0.52,
      trackingError: 0.75,
      managementFee: 0.60,
      custodyFee: 0.15,
      fundSize: 85.23,
      rankPercentile: 40,
    ),
  };
  
  /// 获取基金评分
  static FundScoreResult? scoreFund(String fundCode, {String period = '3y'}) {
    final model = _fundDatabase[fundCode];
    if (model == null) return null;
    return model.calculateScore(period: period);
  }
  
  /// 批量评分并排序
  static List<FundScoreResult> scoreFunds(List<String> fundCodes, {String period = '3y'}) {
    final results = <FundScoreResult>[];
    for (final code in fundCodes) {
      final result = scoreFund(code, period: period);
      if (result != null) {
        results.add(result);
      }
    }
    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return results;
  }
  
  /// 获取某类型基金列表
  static List<FundScoringModel> getFundsByType(String type) {
    final fundCodes = _getFundCodesByType(type);
    return fundCodes
      .map((code) => _fundDatabase[code])
      .whereType<FundScoringModel>()
      .toList();
  }
  
  static List<String> _getFundCodesByType(String type) {
    switch (type) {
      case 'broad':
        return ['510300', '510500', '159915', '159949'];
      case 'sector':
        return ['512880', '512690', '512760', '512010', '512660'];
      case 'bond':
        return ['511010', '511220', '511030'];
      case 'money':
        return ['511880'];
      case 'cross':
        return ['513100', '513050', '513030'];
      default:
        return _fundDatabase.keys.toList();
    }
  }
  
  /// 获取所有基金代码
  static List<String> getAllFundCodes() {
    return _fundDatabase.keys.toList();
  }
  
  /// 获取基金详情
  static FundScoringModel? getFundModel(String fundCode) {
    return _fundDatabase[fundCode];
  }
}
