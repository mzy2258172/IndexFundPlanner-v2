import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../domain/entities/plan.dart';
import '../domain/repositories/plan_repository.dart';
import '../domain/services/portfolio_recommendation.dart';
import '../data/repositories/plan_repository_impl.dart';
import '../../user/domain/entities/user.dart';
import '../../user/presentation/providers/user_provider.dart';

/// 计划Repository Provider
final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepositoryImpl();
});

/// 用户投资计划列表
final userPlansProvider = FutureProvider<List<InvestmentPlan>>((ref) async {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.value;
  if (user == null) return [];
  
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlans(user.id);
});

/// 单个投资计划
final planProvider = FutureProvider.family<InvestmentPlan?, String>((ref, planId) async {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlan(planId);
});

/// 计划状态Notifier
final planNotifierProvider = StateNotifierProvider<PlanNotifier, AsyncValue<void>>((ref) {
  return PlanNotifier(ref.watch(planRepositoryProvider));
});

class PlanNotifier extends StateNotifier<AsyncValue<void>> {
  final PlanRepository _repository;
  
  PlanNotifier(this._repository) : super(const AsyncValue.data(null));
  
  /// 创建投资计划
  Future<InvestmentPlan?> createPlan({
    required String userId,
    required String name,
    required PlanGoalType goalType,
    required double targetAmount,
    double initialCapital = 0,
    required DateTime targetDate,
    required double monthlyInvestment,
    RiskLevel riskLevel = RiskLevel.balanced,
    Portfolio? portfolio,
    SipPlan? sipPlan,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final now = DateTime.now();
      final plan = InvestmentPlan(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        goalType: goalType,
        targetAmount: targetAmount,
        initialCapital: initialCapital,
        currentAmount: initialCapital,
        startDate: now,
        targetDate: targetDate,
        monthlyInvestment: monthlyInvestment,
        portfolio: portfolio,
        sipPlan: sipPlan,
        createdAt: now,
        updatedAt: now,
      );
      
      await _repository.savePlan(plan);
      state = const AsyncValue.data(null);
      return plan;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
  
  /// 更新投资计划
  Future<void> updatePlan(InvestmentPlan plan) async {
    state = const AsyncValue.loading();
    
    try {
      await _repository.updatePlan(plan.copyWith(updatedAt: DateTime.now()));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// 删除投资计划
  Future<void> deletePlan(String planId) async {
    state = const AsyncValue.loading();
    
    try {
      await _repository.deletePlan(planId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// 推荐组合 Provider
final recommendedPortfoliosProvider = Provider.family<List<Portfolio>, ({RiskLevel riskLevel, double amount})>((ref, params) {
  return PortfolioRecommendationEngine.generateRecommendedPortfolios(
    riskLevel: params.riskLevel,
    totalAmount: params.amount,
  );
});

/// 建议月投入 Provider
final suggestedMonthlyInvestmentProvider = Provider.family<double, ({
  double targetAmount,
  int months,
  double initialCapital,
  RiskLevel riskLevel,
})>((ref, params) {
  return PortfolioRecommendationEngine.calculateSuggestedMonthlyInvestment(
    targetAmount: params.targetAmount,
    months: params.months,
    initialCapital: params.initialCapital,
    riskLevel: params.riskLevel,
  );
});

/// 可行性评分 Provider
final feasibilityScoreProvider = Provider.family<double, ({
  double targetAmount,
  int months,
  double initialCapital,
  double monthlyInvestment,
  RiskLevel riskLevel,
})>((ref, params) {
  return PortfolioRecommendationEngine.calculateFeasibilityScore(
    targetAmount: params.targetAmount,
    months: params.months,
    initialCapital: params.initialCapital,
    monthlyInvestment: params.monthlyInvestment,
    riskLevel: params.riskLevel,
  );
});
