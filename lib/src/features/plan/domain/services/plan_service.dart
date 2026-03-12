import '../entities/plan.dart';
import '../entities/plan_records.dart';
import '../services/sip_service.dart';
import '../services/portfolio_recommendation.dart';

/// 投资计划服务
class InvestmentPlanService {
  /// 创建投资计划
  static InvestmentPlan createPlan({
    required String userId,
    required String name,
    required PlanGoalType goalType,
    required double targetAmount,
    double initialCapital = 0,
    required DateTime targetDate,
    double? monthlyInvestment,
  }) {
    final startDate = DateTime.now();
    final months = targetDate.difference(startDate).inDays ~/ 30;
    
    // 如果没有指定月投入额，自动计算
    final monthly = monthlyInvestment ?? 1000.0;
    
    return InvestmentPlan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name,
      goalType: goalType,
      targetAmount: targetAmount,
      initialCapital: initialCapital,
      currentAmount: initialCapital,
      startDate: startDate,
      targetDate: targetDate,
      monthlyInvestment: monthly,
      status: PlanStatus.active,
      createdAt: startDate,
      updatedAt: startDate,
    );
  }
  
  /// 为计划创建投资组合
  static Portfolio createPortfolioForPlan({
    required InvestmentPlan plan,
    required int riskLevel,
  }) {
    final portfolios = PortfolioRecommendationEngine.generateRecommendedPortfolios(
      riskLevel: RiskLevel.values[riskLevel],
      totalAmount: plan.initialCapital > 0 ? plan.initialCapital : plan.monthlyInvestment * 12,
    );
    
    // 返回均衡方案
    return portfolios[1];
  }
  
  /// 为计划创建定投计划
  static SipPlan createSipForPlan({
    required InvestmentPlan plan,
    required String frequency,
    required int investmentDay,
    String strategy = 'normal',
  }) {
    return SipPlanService.createSipPlan(
      planId: plan.id,
      frequency: frequency,
      investmentDay: investmentDay,
      amount: plan.monthlyInvestment,
      strategy: strategy,
    );
  }
  
  /// 完善投资计划（添加组合和定投）
  static InvestmentPlan completePlan({
    required InvestmentPlan plan,
    required Portfolio portfolio,
    SipPlan? sipPlan,
  }) {
    return plan.copyWith(
      portfolio: portfolio,
      sipPlan: sipPlan,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 计算计划进度
  static PlanProgress calculateProgress(InvestmentPlan plan) {
    final now = DateTime.now();
    final totalDays = plan.targetDate.difference(plan.startDate).inDays;
    final passedDays = now.difference(plan.startDate).inDays;
    final remainingDays = plan.targetDate.difference(now).inDays;
    
    // 计算已投入金额
    double investedAmount = plan.initialCapital;
    if (plan.sipPlan != null) {
      investedAmount += plan.sipPlan!.totalInvested;
    }
    
    // 计算收益
    final profitAmount = plan.currentAmount - investedAmount;
    final profitPercent = investedAmount > 0 
      ? (profitAmount / investedAmount) * 100 
      : 0.0;
    
    // 进度百分比
    final progressPercent = (plan.currentAmount / plan.targetAmount) * 100;
    
    // 预期最终金额（基于当前进度和剩余时间）
    final remainingMonths = remainingDays ~/ 30;
    final avgReturn = plan.portfolio != null
      ? ((plan.portfolio!.expectedReturnMin ?? 6) + (plan.portfolio!.expectedReturnMax ?? 10)) / 2 / 100
      : 0.08;
    
    final expectedGrowth = plan.currentAmount * (1 + avgReturn * remainingMonths / 12);
    final expectedSipGrowth = plan.monthlyInvestment * remainingMonths;
    final expectedFinalAmount = expectedGrowth + expectedSipGrowth;
    
    final expectedProgressPercent = (expectedFinalAmount / plan.targetAmount) * 100;
    
    return PlanProgress(
      currentAmount: plan.currentAmount,
      targetAmount: plan.targetAmount,
      progressPercent: progressPercent.clamp(0, 150),
      totalDays: totalDays,
      passedDays: passedDays.clamp(0, totalDays),
      remainingDays: remainingDays.clamp(0, totalDays),
      investedAmount: investedAmount,
      profitAmount: profitAmount,
      profitPercent: profitPercent,
      expectedFinalAmount: expectedFinalAmount,
      expectedProgressPercent: expectedProgressPercent.clamp(0, 150),
    );
  }
  
  /// 计算计划风险指标
  static PlanRiskMetrics calculateRiskMetrics(InvestmentPlan plan) {
    if (plan.portfolio == null) {
      return const PlanRiskMetrics(
        volatility: 0,
        maxDrawdown: 0,
        sharpeRatio: 0,
        riskLevel: '未知',
        riskWarning: '无投资组合数据',
      );
    }
    
    // 使用组合回测计算风险指标
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 365));
    
    final backtest = PortfolioBacktestService.backtest(
      portfolio: plan.portfolio!,
      startDate: startDate,
      endDate: endDate,
    );
    
    // 风险等级判定
    String riskLevel;
    String riskWarning;
    
    if (backtest.volatility <= 15) {
      riskLevel = '低风险';
      riskWarning = '该计划风险较低，适合保守投资者';
    } else if (backtest.volatility <= 25) {
      riskLevel = '中低风险';
      riskWarning = '该计划风险适中，适合稳健投资者';
    } else if (backtest.volatility <= 35) {
      riskLevel = '中风险';
      riskWarning = '该计划风险中等，适合平衡型投资者';
    } else if (backtest.volatility <= 45) {
      riskLevel = '中高风险';
      riskWarning = '该计划风险较高，适合进取型投资者';
    } else {
      riskLevel = '高风险';
      riskWarning = '该计划风险较高，请确保风险承受能力足够';
    }
    
    // 最大回撤警告
    if (backtest.maxDrawdown > 20) {
      riskWarning += '。历史最大回撤较大，请注意风险';
    }
    
    return PlanRiskMetrics(
      volatility: backtest.volatility,
      maxDrawdown: backtest.maxDrawdown,
      sharpeRatio: backtest.sharpeRatio,
      riskLevel: riskLevel,
      riskWarning: riskWarning,
    );
  }
  
  /// 生成计划详细视图
  static PlanDetailView generateDetailView({
    required InvestmentPlan plan,
    List<SipExecution> sipExecutions = const [],
    List<RebalanceRecord> rebalanceRecords = const [],
  }) {
    if (plan.portfolio == null) {
      throw Exception('计划没有关联的投资组合');
    }
    
    final progress = calculateProgress(plan);
    final riskMetrics = calculateRiskMetrics(plan);
    
    return PlanDetailView(
      plan: plan,
      portfolio: plan.portfolio!,
      sipPlan: plan.sipPlan,
      sipExecutions: sipExecutions,
      rebalanceRecords: rebalanceRecords,
      progress: progress,
      riskMetrics: riskMetrics,
    );
  }
  
  /// 检查是否需要调仓
  static bool needRebalance(InvestmentPlan plan) {
    if (plan.portfolio == null) return false;
    
    // 简单规则：每季度检查一次
    final now = DateTime.now();
    final lastUpdate = plan.updatedAt;
    final daysSinceUpdate = now.difference(lastUpdate).inDays;
    
    return daysSinceUpdate >= 90;  // 90天
  }
  
  /// 生成调仓建议
  static RebalanceSuggestion? generateRebalanceSuggestion(InvestmentPlan plan) {
    if (plan.portfolio == null) return null;
    
    // 根据当前风险等级生成建议
    final riskLevel = RiskLevel.values[plan.portfolio!.riskLevel.clamp(0, 4)];
    final totalAmount = plan.currentAmount;
    
    return PortfolioRecommendationEngine.generateRebalanceSuggestion(
      currentPortfolio: plan.portfolio!,
      targetRiskLevel: riskLevel,
      totalAmount: totalAmount,
    );
  }
  
  /// 暂停计划
  static InvestmentPlan pausePlan(InvestmentPlan plan) {
    InvestmentPlan updatedPlan = plan.copyWith(
      status: PlanStatus.paused,
      updatedAt: DateTime.now(),
    );
    
    // 如果有定投计划，也暂停
    if (plan.sipPlan != null && plan.sipPlan!.status == SipStatus.active) {
      final pausedSip = SipPlanService.pauseSip(plan.sipPlan!);
      updatedPlan = updatedPlan.copyWith(sipPlan: pausedSip);
    }
    
    return updatedPlan;
  }
  
  /// 恢复计划
  static InvestmentPlan resumePlan(InvestmentPlan plan) {
    InvestmentPlan updatedPlan = plan.copyWith(
      status: PlanStatus.active,
      updatedAt: DateTime.now(),
    );
    
    // 如果有定投计划，也恢复
    if (plan.sipPlan != null && plan.sipPlan!.status == SipStatus.paused) {
      final resumedSip = SipPlanService.resumeSip(plan.sipPlan!);
      updatedPlan = updatedPlan.copyWith(sipPlan: resumedSip);
    }
    
    return updatedPlan;
  }
  
  /// 终止计划
  static InvestmentPlan terminatePlan(InvestmentPlan plan) {
    InvestmentPlan updatedPlan = plan.copyWith(
      status: PlanStatus.terminated,
      updatedAt: DateTime.now(),
    );
    
    // 如果有定投计划，也终止
    if (plan.sipPlan != null) {
      final terminatedSip = SipPlanService.terminateSip(plan.sipPlan!);
      updatedPlan = updatedPlan.copyWith(sipPlan: terminatedSip);
    }
    
    return updatedPlan;
  }
  
  /// 完成计划
  static InvestmentPlan completePlanAsAchieved(InvestmentPlan plan) {
    return plan.copyWith(
      status: PlanStatus.completed,
      updatedAt: DateTime.now(),
    );
  }
  
  /// 计算计划统计信息
  static PlanStatistics calculateStatistics(List<InvestmentPlan> plans) {
    if (plans.isEmpty) {
      return const PlanStatistics(
        totalPlans: 0,
        activePlans: 0,
        completedPlans: 0,
        totalTargetAmount: 0,
        totalCurrentAmount: 0,
        totalInvested: 0,
        totalProfit: 0,
        averageProgress: 0,
      );
    }
    
    final activePlans = plans.where((p) => p.status == PlanStatus.active).length;
    final completedPlans = plans.where((p) => p.status == PlanStatus.completed).length;
    
    final totalTargetAmount = plans.fold<double>(0, (sum, p) => sum + p.targetAmount);
    final totalCurrentAmount = plans.fold<double>(0, (sum, p) => sum + p.currentAmount);
    
    double totalInvested = 0;
    for (final plan in plans) {
      totalInvested += plan.initialCapital;
      if (plan.sipPlan != null) {
        totalInvested += plan.sipPlan!.totalInvested;
      }
    }
    
    final totalProfit = totalCurrentAmount - totalInvested;
    final averageProgress = plans.fold<double>(0, (sum, p) => sum + p.progress) / plans.length * 100;
    
    return PlanStatistics(
      totalPlans: plans.length,
      activePlans: activePlans,
      completedPlans: completedPlans,
      totalTargetAmount: totalTargetAmount,
      totalCurrentAmount: totalCurrentAmount,
      totalInvested: totalInvested,
      totalProfit: totalProfit,
      averageProgress: averageProgress,
    );
  }
}

/// 计划统计信息
class PlanStatistics {
  final int totalPlans;
  final int activePlans;
  final int completedPlans;
  final double totalTargetAmount;
  final double totalCurrentAmount;
  final double totalInvested;
  final double totalProfit;
  final double averageProgress;
  
  const PlanStatistics({
    required this.totalPlans,
    required this.activePlans,
    required this.completedPlans,
    required this.totalTargetAmount,
    required this.totalCurrentAmount,
    required this.totalInvested,
    required this.totalProfit,
    required this.averageProgress,
  });
  
  double get totalProfitPercent => 
    totalInvested > 0 ? (totalProfit / totalInvested) * 100 : 0;
  
  Map<String, dynamic> toJson() => {
    'totalPlans': totalPlans,
    'activePlans': activePlans,
    'completedPlans': completedPlans,
    'totalTargetAmount': totalTargetAmount,
    'totalCurrentAmount': totalCurrentAmount,
    'totalInvested': totalInvested,
    'totalProfit': totalProfit,
    'averageProgress': averageProgress,
    'totalProfitPercent': totalProfitPercent,
  };
}
