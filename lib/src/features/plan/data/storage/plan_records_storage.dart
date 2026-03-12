import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../domain/entities/plan_records.dart';

/// 定投执行记录存储
class SipExecutionStorage {
  static const String _executionBoxName = 'sip_executions';
  static const String _executionsKey = 'executions';
  
  Box<String>? _box;
  
  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_executionBoxName);
    return _box!;
  }
  
  /// 保存执行记录
  Future<void> saveExecution(SipExecution execution) async {
    final box = await _getBox();
    final jsonStr = box.get(_executionsKey);
    
    List<Map<String, dynamic>> executions = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        executions = jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        executions = [];
      }
    }
    
    executions.add(execution.toJson());
    await box.put(_executionsKey, jsonEncode(executions));
  }
  
  /// 获取指定定投计划的所有执行记录
  Future<List<SipExecution>> getExecutionsBySipPlan(String sipPlanId) async {
    final box = await _getBox();
    final jsonStr = box.get(_executionsKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
        .map((json) => SipExecution.fromJson(json as Map<String, dynamic>))
        .where((e) => e.sipPlanId == sipPlanId)
        .toList()
      ..sort((a, b) => b.executeDate.compareTo(a.executeDate));
    } catch (e) {
      return [];
    }
  }
  
  /// 获取指定日期范围内的执行记录
  Future<List<SipExecution>> getExecutionsByDateRange({
    required String sipPlanId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final allExecutions = await getExecutionsBySipPlan(sipPlanId);
    return allExecutions.where((e) => 
      e.executeDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
      e.executeDate.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }
  
  /// 获取最近的执行记录
  Future<SipExecution?> getLatestExecution(String sipPlanId) async {
    final executions = await getExecutionsBySipPlan(sipPlanId);
    return executions.isNotEmpty ? executions.first : null;
  }
  
  /// 更新执行记录状态
  Future<void> updateExecutionStatus({
    required String executionId,
    required SipExecutionStatus status,
    String? failReason,
  }) async {
    final box = await _getBox();
    final jsonStr = box.get(_executionsKey);
    if (jsonStr == null) return;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> executions = jsonList.cast<Map<String, dynamic>>();
      
      final index = executions.indexWhere((e) => e['id'] == executionId);
      if (index != -1) {
        executions[index]['status'] = status.index;
        if (failReason != null) {
          executions[index]['failReason'] = failReason;
        }
        await box.put(_executionsKey, jsonEncode(executions));
      }
    } catch (e) {
      // Handle error
    }
  }
  
  /// 删除指定定投计划的所有执行记录
  Future<void> deleteExecutionsBySipPlan(String sipPlanId) async {
    final box = await _getBox();
    final jsonStr = box.get(_executionsKey);
    if (jsonStr == null) return;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> executions = jsonList.cast<Map<String, dynamic>>();
      
      executions.removeWhere((e) => e['sipPlanId'] == sipPlanId);
      await box.put(_executionsKey, jsonEncode(executions));
    } catch (e) {
      // Handle error
    }
  }
  
  /// 获取执行统计
  Future<SipExecutionStats> getExecutionStats(String sipPlanId) async {
    final executions = await getExecutionsBySipPlan(sipPlanId);
    
    if (executions.isEmpty) {
      return const SipExecutionStats(
        totalExecutions: 0,
        successCount: 0,
        failedCount: 0,
        totalAmount: 0,
        totalShares: 0,
        avgAmount: 0,
      );
    }
    
    final successCount = executions.where((e) => e.status == SipExecutionStatus.success).length;
    final failedCount = executions.where((e) => e.status == SipExecutionStatus.failed).length;
    final totalAmount = executions.fold<double>(0, (sum, e) => sum + e.amount);
    final totalShares = executions.fold<double>(0, (sum, e) => sum + e.shares);
    
    return SipExecutionStats(
      totalExecutions: executions.length,
      successCount: successCount,
      failedCount: failedCount,
      totalAmount: totalAmount,
      totalShares: totalShares,
      avgAmount: totalAmount / executions.length,
    );
  }
  
  /// 清空所有执行记录
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}

/// 执行统计
class SipExecutionStats {
  final int totalExecutions;
  final int successCount;
  final int failedCount;
  final double totalAmount;
  final double totalShares;
  final double avgAmount;
  
  const SipExecutionStats({
    required this.totalExecutions,
    required this.successCount,
    required this.failedCount,
    required this.totalAmount,
    required this.totalShares,
    required this.avgAmount,
  });
  
  double get successRate => 
    totalExecutions > 0 ? (successCount / totalExecutions) * 100 : 0;
  
  Map<String, dynamic> toJson() => {
    'totalExecutions': totalExecutions,
    'successCount': successCount,
    'failedCount': failedCount,
    'totalAmount': totalAmount,
    'totalShares': totalShares,
    'avgAmount': avgAmount,
    'successRate': successRate,
  };
}

/// 调仓记录存储
class RebalanceRecordStorage {
  static const String _rebalanceBoxName = 'rebalance_records';
  static const String _recordsKey = 'records';
  
  Box<String>? _box;
  
  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_rebalanceBoxName);
    return _box!;
  }
  
  /// 保存调仓记录
  Future<void> saveRecord(RebalanceRecord record) async {
    final box = await _getBox();
    final jsonStr = box.get(_recordsKey);
    
    List<Map<String, dynamic>> records = [];
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        records = jsonList.cast<Map<String, dynamic>>();
      } catch (e) {
        records = [];
      }
    }
    
    records.add(record.toJson());
    await box.put(_recordsKey, jsonEncode(records));
  }
  
  /// 获取指定投资计划的调仓记录
  Future<List<RebalanceRecord>> getRecordsByPlan(String planId) async {
    final box = await _getBox();
    final jsonStr = box.get(_recordsKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
        .map((json) => RebalanceRecord.fromJson(json as Map<String, dynamic>))
        .where((r) => r.planId == planId)
        .toList()
      ..sort((a, b) => b.executeDate.compareTo(a.executeDate));
    } catch (e) {
      return [];
    }
  }
  
  /// 获取指定组合的调仓记录
  Future<List<RebalanceRecord>> getRecordsByPortfolio(String portfolioId) async {
    final box = await _getBox();
    final jsonStr = box.get(_recordsKey);
    if (jsonStr == null) return [];
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      return jsonList
        .map((json) => RebalanceRecord.fromJson(json as Map<String, dynamic>))
        .where((r) => r.portfolioId == portfolioId)
        .toList()
      ..sort((a, b) => b.executeDate.compareTo(a.executeDate));
    } catch (e) {
      return [];
    }
  }
  
  /// 获取最近的调仓记录
  Future<RebalanceRecord?> getLatestRecord(String planId) async {
    final records = await getRecordsByPlan(planId);
    return records.isNotEmpty ? records.first : null;
  }
  
  /// 删除指定投资计划的调仓记录
  Future<void> deleteRecordsByPlan(String planId) async {
    final box = await _getBox();
    final jsonStr = box.get(_recordsKey);
    if (jsonStr == null) return;
    
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final List<Map<String, dynamic>> records = jsonList.cast<Map<String, dynamic>>();
      
      records.removeWhere((r) => r['planId'] == planId);
      await box.put(_recordsKey, jsonEncode(records));
    } catch (e) {
      // Handle error
    }
  }
  
  /// 清空所有调仓记录
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
