import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/entities/plan.dart';
import '../domain/repositories/plan_repository.dart';

class PlanRepositoryImpl implements PlanRepository {
  static const String _planBoxName = 'plan_box';
  static const String _plansKey = 'plans';
  
  Box<String>? _box;
  
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
        .toList();
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
}
