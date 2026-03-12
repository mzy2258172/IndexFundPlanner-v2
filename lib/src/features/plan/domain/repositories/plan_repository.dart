import '../entities/plan.dart';

abstract class PlanRepository {
  /// 获取用户所有投资计划
  Future<List<InvestmentPlan>> getPlans(String userId);
  
  /// 获取单个投资计划
  Future<InvestmentPlan?> getPlan(String planId);
  
  /// 保存投资计划
  Future<void> savePlan(InvestmentPlan plan);
  
  /// 更新投资计划
  Future<void> updatePlan(InvestmentPlan plan);
  
  /// 删除投资计划
  Future<void> deletePlan(String planId);
  
  /// 更新计划当前金额
  Future<void> updatePlanAmount(String planId, double amount);
}
