import 'package:flutter_test/flutter_test.dart';
import '../lib/src/features/plan/domain/services/portfolio_recommendation.dart';
import '../lib/src/features/plan/domain/services/fund_scoring.dart';
import '../lib/src/features/plan/domain/services/sip_service.dart';
import '../lib/src/features/plan/domain/services/plan_service.dart';
import '../lib/src/features/plan/domain/entities/plan.dart';
import '../lib/src/features/user/domain/entities/user.dart';

void main() {
  group('基金评分模型测试', () {
    test('沪深300ETF评分', () {
      final result = FundScoringService.scoreFund('510300');
      expect(result, isNotNull);
      expect(result!.fundCode, equals('510300'));
      expect(result.totalScore, greaterThanOrEqualTo(0));
      expect(result.totalScore, lessThanOrEqualTo(100));
      expect(result.isRecommended, isA<bool>());
      print('沪深300ETF评分: ${result.totalScore}, 评级: ${result.rating}');
    });
    
    test('批量评分测试', () {
      final codes = ['510300', '510500', '159915'];
      final results = FundScoringService.scoreFunds(codes);
      expect(results.length, equals(3));
      
      // 验证已排序
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].totalScore, greaterThanOrEqualTo(results[i + 1].totalScore));
      }
      
      print('批量评分结果:');
      for (final result in results) {
        print('  ${result.fundName}: ${result.totalScore}');
      }
    });
    
    test('评分维度测试', () {
      final result = FundScoringService.scoreFund('512760');
      expect(result, isNotNull);
      
      // 验证各维度评分
      expect(result!.returnScore, greaterThanOrEqualTo(0));
      expect(result.returnScore, lessThanOrEqualTo(40));
      expect(result.riskScore, greaterThanOrEqualTo(0));
      expect(result.riskScore, lessThanOrEqualTo(30));
      expect(result.trackingScore, greaterThanOrEqualTo(0));
      expect(result.trackingScore, lessThanOrEqualTo(15));
      expect(result.feeScore, greaterThanOrEqualTo(0));
      expect(result.feeScore, lessThanOrEqualTo(10));
      expect(result.liquidityScore, greaterThanOrEqualTo(0));
      expect(result.liquidityScore, lessThanOrEqualTo(5));
      
      print('半导体ETF评分详情:');
      print('  收益评分: ${result.returnScore}/40');
      print('  风险评分: ${result.riskScore}/30');
      print('  跟踪评分: ${result.trackingScore}/15');
      print('  费率评分: ${result.feeScore}/10');
      print('  流动性评分: ${result.liquidityScore}/5');
    });
  });
  
  group('组合推荐算法测试', () {
    test('资产配置测试', () {
      // 测试不同风险等级的资产配置
      final conservative = PortfolioRecommendationEngine.getAssetAllocation(RiskLevel.conservative);
      expect(conservative['money'], equals(0.40));
      expect(conservative['bond'], equals(0.50));
      expect(conservative['broad'], equals(0.10));
      
      final balanced = PortfolioRecommendationEngine.getAssetAllocation(RiskLevel.balanced);
      expect(balanced['broad'], equals(0.40));
      expect(balanced['sector'], equals(0.20));
      
      print('保守型配置: $conservative');
      print('平衡型配置: $balanced');
    });
    
    test('三档方案生成测试', () {
      final portfolios = PortfolioRecommendationEngine.generateRecommendedPortfolios(
        riskLevel: RiskLevel.balanced,
        totalAmount: 100000,
      );
      
      expect(portfolios.length, equals(3));
      expect(portfolios[0].name, equals('稳健方案'));
      expect(portfolios[1].name, equals('均衡方案'));
      expect(portfolios[2].name, equals('进取方案'));
      
      // 验证配置
      for (final portfolio in portfolios) {
        expect(portfolio.allocations.isNotEmpty, isTrue);
        expect(portfolio.totalAmount, equals(100000));
        print('${portfolio.name}: ${portfolio.allocations.length} 只基金');
      }
    });
    
    test('建议月投入额计算测试', () {
      final monthly = PortfolioRecommendationEngine.calculateSuggestedMonthlyInvestment(
        targetAmount: 500000,
        months: 60,
        initialCapital: 50000,
        riskLevel: RiskLevel.balanced,
      );
      
      expect(monthly, greaterThan(0));
      expect(monthly % 100, equals(0)); // 应该是100的整数倍
      
      print('目标 50 万，5 年期限，初始 5 万');
      print('建议月投入: ¥$monthly');
    });
    
    test('可行性评分测试', () {
      final score = PortfolioRecommendationEngine.calculateFeasibilityScore(
        targetAmount: 500000,
        months: 60,
        initialCapital: 50000,
        monthlyInvestment: 5000,
        riskLevel: RiskLevel.balanced,
      );
      
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(150));
      print('可行性评分: $score%');
    });
  });
  
  group('定投计算服务测试', () {
    test('下次执行日期计算', () {
      // 每月定投
      final monthly = SipCalculationService.calculateNextExecuteDate(
        frequency: 'monthly',
        investmentDay: 15,
      );
      expect(monthly.day, equals(15));
      expect(monthly.isAfter(DateTime.now()), isTrue);
      
      // 每周定投
      final weekly = SipCalculationService.calculateNextExecuteDate(
        frequency: 'weekly',
        investmentDay: 1, // 周一
      );
      expect(weekly.weekday, equals(1));
      expect(weekly.isAfter(DateTime.now()), isTrue);
      
      print('每月定投下次执行: $monthly');
      print('每周定投下次执行: $weekly');
    });
    
    test('定投复利终值计算', () {
      final fv = SipCalculationService.calculateFutureValue(
        monthlyInvestment: 5000,
        months: 60,
        annualReturn: 0.08,
        initialCapital: 50000,
      );
      
      expect(fv, greaterThan(0));
      print('月投 5000，年化 8%，5 年终值: ¥${fv.toStringAsFixed(2)}');
    });
    
    test('均线策略调整系数计算', () {
      // 低估情况
      final undervalued = SipCalculationService.calculateMaAdjustment(
        currentNav: 4.0,
        maValue: 5.0,
      );
      expect(undervalued, greaterThan(1.0));
      
      // 高估情况
      final overvalued = SipCalculationService.calculateMaAdjustment(
        currentNav: 6.0,
        maValue: 5.0,
      );
      expect(overvalued, lessThan(1.0));
      
      print('低估 20%，调整系数: $undervalued');
      print('高估 20%，调整系数: $overvalued');
    });
    
    test('价值平均策略计算', () {
      final amount = SipCalculationService.calculateValueAverageInvestment(
        targetGrowth: 5000,
        currentValue: 100000,
        baseAmount: 5000,
      );
      
      // 应该等于目标增长额
      expect(amount, equals(5000));
      print('价值平均策略投入额: ¥$amount');
    });
    
    test('定投计划创建', () {
      final sipPlan = SipPlanService.createSipPlan(
        planId: 'test_plan',
        frequency: 'monthly',
        investmentDay: 15,
        amount: 5000,
        strategy: 'ma',
      );
      
      expect(sipPlan.frequency, equals('monthly'));
      expect(sipPlan.investmentDay, equals(15));
      expect(sipPlan.amount, equals(5000));
      expect(sipPlan.strategy, equals('ma'));
      expect(sipPlan.status, equals(SipStatus.active));
      expect(sipPlan.nextExecuteDate, isNotNull);
      
      print('定投计划创建成功: ${sipPlan.id}');
    });
  });
  
  group('投资计划服务测试', () {
    test('创建投资计划', () {
      final plan = InvestmentPlanService.createPlan(
        userId: 'user_001',
        name: '教育金计划',
        goalType: PlanGoalType.education,
        targetAmount: 500000,
        initialCapital: 50000,
        targetDate: DateTime.now().add(const Duration(days: 365 * 5)),
      );
      
      expect(plan.userId, equals('user_001'));
      expect(plan.name, equals('教育金计划'));
      expect(plan.targetAmount, equals(500000));
      expect(plan.initialCapital, equals(50000));
      expect(plan.status, equals(PlanStatus.active));
      
      print('投资计划创建成功: ${plan.id}');
    });
    
    test('计划进度计算', () {
      final plan = InvestmentPlanService.createPlan(
        userId: 'user_001',
        name: '测试计划',
        goalType: PlanGoalType.wealth,
        targetAmount: 100000,
        initialCapital: 20000,
        targetDate: DateTime.now().add(const Duration(days: 365)),
      );
      
      final progress = InvestmentPlanService.calculateProgress(plan);
      
      expect(progress.targetAmount, equals(100000));
      expect(progress.progressPercent, greaterThan(0));
      expect(progress.remainingDays, greaterThan(0));
      
      print('计划进度: ${progress.progressPercent.toStringAsFixed(1)}%');
      print('剩余天数: ${progress.remainingDays}');
      print('进度状态: ${progress.progressStatus}');
    });
    
    test('计划统计计算', () {
      final plans = [
        InvestmentPlanService.createPlan(
          userId: 'user_001',
          name: '计划1',
          goalType: PlanGoalType.education,
          targetAmount: 100000,
          targetDate: DateTime.now().add(const Duration(days: 365)),
        ),
        InvestmentPlanService.createPlan(
          userId: 'user_001',
          name: '计划2',
          goalType: PlanGoalType.retirement,
          targetAmount: 200000,
          targetDate: DateTime.now().add(const Duration(days: 365 * 2)),
        ),
      ];
      
      final stats = InvestmentPlanService.calculateStatistics(plans);
      
      expect(stats.totalPlans, equals(2));
      expect(stats.activePlans, equals(2));
      expect(stats.totalTargetAmount, equals(300000));
      
      print('总计划数: ${stats.totalPlans}');
      print('活跃计划: ${stats.activePlans}');
      print('目标总额: ¥${stats.totalTargetAmount}');
    });
  });
  
  group('组合回测测试', () {
    test('组合回测计算', () {
      final portfolios = PortfolioRecommendationEngine.generateRecommendedPortfolios(
        riskLevel: RiskLevel.balanced,
        totalAmount: 100000,
      );
      
      final result = PortfolioBacktestService.backtest(
        portfolio: portfolios[1],
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
      );
      
      expect(result.navCurve.isNotEmpty, isTrue);
      expect(result.totalReturn, isNotNull);
      expect(result.annualReturn, isNotNull);
      expect(result.maxDrawdown, greaterThanOrEqualTo(0));
      expect(result.sharpeRatio, isNotNull);
      
      print('回测结果:');
      print('  总收益: ${result.totalReturn.toStringAsFixed(2)}%');
      print('  年化收益: ${result.annualReturn.toStringAsFixed(2)}%');
      print('  最大回撤: ${result.maxDrawdown.toStringAsFixed(2)}%');
      print('  夏普比率: ${result.sharpeRatio.toStringAsFixed(2)}');
      print('  波动率: ${result.volatility.toStringAsFixed(2)}%');
      print('  交易日数: ${result.tradingDays}');
    });
  });
}
