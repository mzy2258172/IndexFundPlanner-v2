import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/entities/plan.dart';
import '../domain/entities/plan_records.dart';
import '../domain/repositories/plan_repository.dart';
import '../domain/services/plan_service.dart';
import '../domain/services/sip_service.dart';
import 'storage/plan_records_storage.dart';

/// 增强的计划存储实现
class EnhancedPlanRepositoryImpl implements PlanRepository {
  static const String _planBoxName = 'enhanced_plan_box';
  static const String _plansKey = 'plans';
  
  Box<String>? _box;
  final SipExecutionStorage _executionStorage = SipExecutionStorage();
  final RebalanceRecordStorage _rebalanceStorage = RebalanceRecordStorage();
  
  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_planBoxName);
    return _box!;
  }
  
  @override
  Future<List<InvestmentPlan>> getPlans(String userId) async {
    final box = await _getBox();
    final jsonStr = box.get(_plansKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
        .map((json) => InvestmentPlan.fromJson(json as Map<String, dynamic>))
        .where((plan) => plan.userId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<InvestmentPlan?> getPlan(String planId) async {
    final box = await _getBox();
    final jsonStr = box.get(_plansKey);
    if (jsonStr == null) return null;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final plans = jsonList
        .map((json) => InvestmentPlan.fromJson(json as Map<String, dynamic>))
        .toList();
      return plans.firstWhere(
        (plan) => plan.id == planId,
        orElse: () => throw Exception('Plan not found'),
      );
    } catch (e) {
      return null;
    }
  }
  
  @override
  Future<void> savePlan(InvestmentPlan plan) async {
    final box = await _getBox();
    final jsonStr = box.get(_plansKey);
    
    List<Map<String, dynamic>> plans = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        plans = jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        plans = [];
      }
    }
    
    plans.add(plan.toJson());
    await box.put(_plansKey, jsonEncode(plans));
  }
  
  @override
  Future<void> updatePlan(InvestmentPlan plan) async {
    final box = await _getBox();
    final jsonStr = box.get(_plansKey);
    
    if (jsonStr == null) return;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> plans = jsonList.cast<Map<String, dynamic>>();
      
      final index = plans.indexWhere((p) => p['id'] == plan.id);
      if (index != -1) {
        plans[index] = plan.toJson();
        await box.put(_plansKey, jsonEncode(plans));
      }
    } catch (e) {
      // Handle error
    }
  }
  
  @override
  Future<void> deletePlan(String planId) async {
    final box = await _getBox();
    final jsonStr = box.get(_plansKey);
    
    if (jsonStr == null) return;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> plans = jsonList.cast<Map<String, dynamic>>();
      
      plans.removeWhere((p) => p['id'] == planId);
      await box.put(_plansKey, jsonEncode(plans));
      
      // 删除相关的执行记录和调仓记录
      await _executionStorage.deleteExecutionsBySipPlan(planId);
      await _rebalanceStorage.deleteRecordsByPlan(planId);
    } catch (e) {
      // Handle error
    }
  }
  
  @override
  Future<void> updatePlanAmount(String planId, double amount) async {
    final plan = await getPlan(planId);
    if (plan != null) {
      await updatePlan(plan.copyWith(currentAmount: amount));
    }
  }
  
  /// 获取计划详细视图
  Future<PlanDetailView?> getPlanDetailView(String planId) async {
    final plan = await getPlan(planId);
    if (plan == null || plan.portfolio == null) return null;
    
    // 获取执行记录
    List<SipExecution> executions = [];
    if (plan.sipPlan != null) {
      executions = await _executionStorage.getExecutionsBySipPlan(plan.sipPlan!.id);
    }
    
    // 获取调仓记录
    final rebalanceRecords = await _rebalanceStorage.getRecordsByPlan(planId);
    
    // 使用服务生成详细视图
    return InvestmentPlanService.generateDetailView(
      plan: plan,
      sipExecutions: executions,
      rebalanceRecords: rebalanceRecords,
    );
  }
  
  /// 获取用户的活跃计划
  Future<List<InvestmentPlan>> getActivePlans(String userId) async {
    final plans = await getPlans(userId);
    return plans.where((p) => p.status == PlanStatus.active).toList();
  }
  
  /// 获取用户的已完成计划
  Future<List<InvestmentPlan>> getCompletedPlans(String userId) async {
    final plans = await getPlans(userId);
    return plans.where((p) => p.status == PlanStatus.completed).toList();
  }
  
  /// 按目标类型筛选计划
  Future<List<InvestmentPlan>> getPlansByGoalType(String userId, PlanGoalType goalType) async {
    final plans = await getPlans(userId);
    return plans.where((p) => p.goalType == goalType).toList();
  }
  
  /// 获取需要提醒的定投计划
  Future<List<InvestmentPlan>> getPlansNeedReminder(String userId) async {
    final activePlans = await getActivePlans(userId);
    final plansWithSip = activePlans.where((p) => 
      p.sipPlan != null && p.sipPlan!.status == SipStatus.active
    ).toList();
    
    final now = DateTime.now();
    return plansWithSip.where((p) => 
      SipReminderService.shouldRemind(plan: p.sipPlan!, now: now)
    ).toList();
  }
  
  /// 保存定投执行记录
  Future<void> saveSipExecution(SipExecution execution) async {
    await _executionStorage.saveExecution(execution);
    
    // 更新定投计划的累计投入
    final plan = await getPlan(execution.sipPlanId);
    if (plan != null && plan.sipPlan != null) {
      final updatedSip = SipPlan(
        id: plan.sipPlan!.id,
        frequency: plan.sipPlan!.frequency,
        investmentDay: plan.sipPlan!.investmentDay,
        amount: plan.sipPlan!.amount,
        strategy: plan.sipPlan!.strategy,
        status: plan.sipPlan!.status,
        nextExecuteDate: plan.sipPlan!.nextExecuteDate,
        totalInvested: plan.sipPlan!.totalInvested + execution.amount,
      );
      
      await updatePlan(plan.copyWith(
        sipPlan: updatedSip,
        currentAmount: plan.currentAmount + execution.amount,
      ));
    }
  }
  
  /// 获取定投执行记录
  Future<List<SipExecution>> getSipExecutions(String sipPlanId) async {
    return _executionStorage.getExecutionsBySipPlan(sipPlanId);
  }
  
  /// 保存调仓记录
  Future<void> saveRebalanceRecord(RebalanceRecord record) async {
    await _rebalanceStorage.saveRecord(record);
  }
  
  /// 获取调仓记录
  Future<List<RebalanceRecord>> getRebalanceRecords(String planId) async {
    return _rebalanceStorage.getRecordsByPlan(planId);
  }
  
  /// 获取执行统计
  Future<SipExecutionStats> getSipExecutionStats(String sipPlanId) async {
    return _executionStorage.getExecutionStats(sipPlanId);
  }
  
  /// 批量更新计划
  Future<void> updatePlans(List<InvestmentPlan> plans) async {
    final box = await _getBox();
    
    final plansJson = plans.map((p) => p.toJson()).toList();
    await box.put(_plansKey, jsonEncode(plansJson));
  }
  
  /// 清空所有数据
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
    await _executionStorage.clearAll();
    await _rebalanceStorage.clearAll();
  }
  
  /// 导出计划数据
  Future<String> exportPlans(String userId) async {
    final plans = await getPlans(userId);
    final exportData = <String, dynamic>{
      'userId': userId,
      'exportDate': DateTime.now().toIso8601String(),
      'plans': plans.map((p) => p.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }
  
  /// 导入计划数据
  Future<void> importPlans(String jsonData) async {
    try {
      final data = jsonDecode(jsonData) as Map<String, dynamic>;
      final plans = (data['plans'] as List)
        .map((p) => InvestmentPlan.fromJson(p as Map<String, dynamic>))
        .toList();
      
      for (final plan in plans) {
        await savePlan(plan);
      }
    } catch (e) {
      throw Exception('导入失败：数据格式错误');
    }
  }
}
