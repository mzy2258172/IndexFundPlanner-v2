import '../entities/plan.dart';

/// 定投策略类型
enum SipStrategy {
  normal,      // 普通定投
  ma,          // 均线策略
  valueAvg,    // 价值平均策略
}

extension SipStrategyExtension on SipStrategy {
  String get displayName {
    switch (this) {
      case SipStrategy.normal:
        return '普通定投';
      case SipStrategy.ma:
        return '均线策略';
      case SipStrategy.valueAvg:
        return '价值平均策略';
    }
  }
  
  String get description {
    switch (this) {
      case SipStrategy.normal:
        return '每期固定金额';
      case SipStrategy.ma:
        return '低估多投，高估少投';
      case SipStrategy.valueAvg:
        return '保持市值稳定增长';
    }
  }
}

/// 定投计算服务
class SipCalculationService {
  /// 计算下次执行日期
  static DateTime calculateNextExecuteDate({
    required String frequency,
    required int investmentDay,
    DateTime? fromDate,
  }) {
    final now = fromDate ?? DateTime.now();
    
    switch (frequency) {
      case 'weekly':
        // 每周：计算下个投资日（周一=1，周日=7）
        final targetWeekday = investmentDay.clamp(1, 7);
        var next = now;
        while (next.weekday != targetWeekday || next.isBefore(now) || next.day == now.day) {
          next = next.add(const Duration(days: 1));
        }
        return next;
        
      case 'biweekly':
        // 每两周：从本月投资日开始
        var next = DateTime(now.year, now.month, investmentDay);
        if (next.isBefore(now) || next.day == now.day) {
          next = next.add(const Duration(days: 14));
        }
        return next;
        
      case 'monthly':
      default:
        // 每月：下个月的投资日
        var next = DateTime(now.year, now.month, investmentDay);
        if (next.isBefore(now) || next.day == now.day) {
          // 下个月
          if (now.month == 12) {
            next = DateTime(now.year + 1, 1, investmentDay);
          } else {
            next = DateTime(now.year, now.month + 1, investmentDay);
          }
        }
        return next;
    }
  }
  
  /// 计算定投复利终值
  static double calculateFutureValue({
    required double monthlyInvestment,
    required int months,
    required double annualReturn,
    double initialCapital = 0,
  }) {
    final monthlyReturn = annualReturn / 12;
    
    // 初始本金复利终值
    final fvInitial = initialCapital * (1 + monthlyReturn) * months;
    
    // 定投复利终值（期初付）
    double fvSip;
    if (monthlyReturn == 0) {
      fvSip = monthlyInvestment * months;
    } else {
      fvSip = monthlyInvestment * 
        ((1 + monthlyReturn) * months - 1) / monthlyReturn * 
        (1 + monthlyReturn);
    }
    
    return fvInitial + fvSip;
  }
  
  /// 反推月投入额
  static double calculateMonthlyInvestment({
    required double targetAmount,
    required int months,
    required double annualReturn,
    double initialCapital = 0,
  }) {
    final monthlyReturn = annualReturn / 12;
    
    // 初始本金复利终值
    final fvInitial = initialCapital * (1 + monthlyReturn) * months;
    
    // 需要通过定投达成的金额
    final fvNeeded = targetAmount - fvInitial;
    
    if (fvNeeded <= 0) return 0;
    
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
  
  /// 计算均线策略调整系数
  static double calculateMaAdjustment({
    required double currentNav,
    required double maValue,
  }) {
    // 计算偏离度
    final deviation = (currentNav - maValue) / maValue;
    
    // 调整系数
    if (deviation <= -0.20) {
      return 2.0;   // 低估超过 20%，投入 2 倍
    } else if (deviation <= -0.10) {
      return 1.5;   // 低估 10%-20%，投入 1.5 倍
    } else if (deviation <= 0) {
      return 1.2;   // 低估 0-10%，投入 1.2 倍
    } else if (deviation <= 0.10) {
      return 1.0;   // 高估 0-10%，投入 1.0 倍
    } else if (deviation <= 0.20) {
      return 0.8;   // 高估 10%-20%，投入 0.8 倍
    } else {
      return 0.5;   // 高估超过 20%，投入 0.5 倍
    }
  }
  
  /// 计算价值平均策略投入额
  static double calculateValueAverageInvestment({
    required double targetGrowth,
    required double currentValue,
    required double baseAmount,
  }) {
    // 目标市值 = 上期市值 + 目标增长
    final targetValue = currentValue + targetGrowth;
    
    // 本期投入 = 目标市值 - 当前市值
    var investmentAmount = targetValue - currentValue;
    
    // 限制赎回（最多赎回 50%）
    if (investmentAmount < -currentValue * 0.5) {
      investmentAmount = -currentValue * 0.5;
    }
    
    return investmentAmount;
  }
  
  /// 计算定投收益
  static SipReturnResult calculateSipReturn({
    required List<double> investments,
    required double currentValue,
  }) {
    final totalInvested = investments.fold<double>(0, (sum, i) => sum + i);
    final profit = currentValue - totalInvested;
    final returnRate = totalInvested > 0 ? profit / totalInvested : 0.0;
    
    // 计算年化收益率（XIRR 简化版）
    // 假设每月投入，使用简单年化计算
    final months = investments.length;
    final annualizedReturn = months > 0 
      ? (1 + returnRate) * (12 / months) - 1 
      : 0.0;
    
    return SipReturnResult(
      totalInvested: totalInvested,
      currentValue: currentValue,
      profit: profit,
      returnRate: returnRate * 100,
      annualizedReturn: annualizedReturn * 100,
      investmentCount: investments.length,
    );
  }
}

/// 定投收益结果
class SipReturnResult {
  final double totalInvested;
  final double currentValue;
  final double profit;
  final double returnRate;
  final double annualizedReturn;
  final int investmentCount;
  
  const SipReturnResult({
    required this.totalInvested,
    required this.currentValue,
    required this.profit,
    required this.returnRate,
    required this.annualizedReturn,
    required this.investmentCount,
  });
  
  bool get isProfitable => profit > 0;
  
  Map<String, dynamic> toJson() => {
    'totalInvested': totalInvested,
    'currentValue': currentValue,
    'profit': profit,
    'returnRate': returnRate,
    'annualizedReturn': annualizedReturn,
    'investmentCount': investmentCount,
    'isProfitable': isProfitable,
  };
}

/// 定投计划管理服务
class SipPlanService {
  /// 创建定投计划
  static SipPlan createSipPlan({
    required String planId,
    required String frequency,
    required int investmentDay,
    required double amount,
    String strategy = 'normal',
  }) {
    final nextExecuteDate = SipCalculationService.calculateNextExecuteDate(
      frequency: frequency,
      investmentDay: investmentDay,
    );
    
    return SipPlan(
      id: 'sip_${DateTime.now().millisecondsSinceEpoch}',
      frequency: frequency,
      investmentDay: investmentDay,
      amount: amount,
      strategy: strategy,
      status: SipStatus.active,
      nextExecuteDate: nextExecuteDate,
      totalInvested: 0,
    );
  }
  
  /// 更新下次执行日期
  static SipPlan updateNextExecuteDate(SipPlan plan) {
    final nextDate = SipCalculationService.calculateNextExecuteDate(
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
      fromDate: plan.nextExecuteDate,
    );
    
    return SipPlan(
      id: plan.id,
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
      amount: plan.amount,
      strategy: plan.strategy,
      status: plan.status,
      nextExecuteDate: nextDate,
      totalInvested: plan.totalInvested,
    );
  }
  
  /// 暂停定投
  static SipPlan pauseSip(SipPlan plan) {
    return SipPlan(
      id: plan.id,
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
      amount: plan.amount,
      strategy: plan.strategy,
      status: SipStatus.paused,
      nextExecuteDate: plan.nextExecuteDate,
      totalInvested: plan.totalInvested,
    );
  }
  
  /// 恢复定投
  static SipPlan resumeSip(SipPlan plan) {
    final nextDate = SipCalculationService.calculateNextExecuteDate(
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
    );
    
    return SipPlan(
      id: plan.id,
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
      amount: plan.amount,
      strategy: plan.strategy,
      status: SipStatus.active,
      nextExecuteDate: nextDate,
      totalInvested: plan.totalInvested,
    );
  }
  
  /// 终止定投
  static SipPlan terminateSip(SipPlan plan) {
    return SipPlan(
      id: plan.id,
      frequency: plan.frequency,
      investmentDay: plan.investmentDay,
      amount: plan.amount,
      strategy: plan.strategy,
      status: SipStatus.terminated,
      nextExecuteDate: null,
      totalInvested: plan.totalInvested,
    );
  }
  
  /// 执行定投
  static SipExecutionResult executeSip({
    required SipPlan plan,
    required double currentNav,
    double? maValue,
    double? targetGrowth,
  }) {
    if (plan.status != SipStatus.active) {
      return SipExecutionResult(
        success: false,
        amount: 0,
        message: '定投计划未激活',
        adjustment: 1.0,
      );
    }
    
    double actualAmount = plan.amount;
    double adjustment = 1.0;
    String message = '普通定投执行成功';
    
    // 根据策略调整金额
    switch (plan.strategy) {
      case 'ma':
        if (maValue != null && maValue > 0) {
          adjustment = SipCalculationService.calculateMaAdjustment(
            currentNav: currentNav,
            maValue: maValue,
          );
          actualAmount = plan.amount * adjustment;
          message = '均线策略执行成功，调整系数: ${adjustment.toStringAsFixed(2)}';
        }
        break;
        
      case 'value_avg':
        // 价值平均策略需要更复杂的计算
        // 这里简化处理
        if (targetGrowth != null) {
          actualAmount = SipCalculationService.calculateValueAverageInvestment(
            targetGrowth: targetGrowth,
            currentValue: plan.totalInvested,
            baseAmount: plan.amount,
          );
          adjustment = actualAmount / plan.amount;
          message = '价值平均策略执行成功';
        }
        break;
    }
    
    // 确保金额在合理范围内
    actualAmount = actualAmount.clamp(10.0, 500000.0);
    
    return SipExecutionResult(
      success: true,
      amount: actualAmount,
      message: message,
      adjustment: adjustment,
    );
  }
}

/// 定投执行结果
class SipExecutionResult {
  final bool success;
  final double amount;
  final String message;
  final double adjustment;
  
  const SipExecutionResult({
    required this.success,
    required this.amount,
    required this.message,
    required this.adjustment,
  });
}

/// 定投提醒服务
class SipReminderService {
  /// 检查是否需要提醒
  static bool shouldRemind({
    required SipPlan plan,
    required DateTime now,
    int daysBefore = 1,
  }) {
    if (plan.status != SipStatus.active) return false;
    if (plan.nextExecuteDate == null) return false;
    
    final reminderDate = plan.nextExecuteDate!.subtract(Duration(days: daysBefore));
    return now.year == reminderDate.year &&
           now.month == reminderDate.month &&
           now.day == reminderDate.day;
  }
  
  /// 获取提醒消息
  static SipReminderMessage getReminderMessage(SipPlan plan) {
    if (plan.nextExecuteDate == null) {
      return SipReminderMessage(
        title: '定投提醒',
        content: '您的定投计划暂无下次执行日期',
        type: 'warning',
      );
    }
    
    final daysUntil = plan.nextExecuteDate!.difference(DateTime.now()).inDays;
    
    String content;
    if (daysUntil == 0) {
      content = '您的定投计划将于今日执行，预计扣款 ${plan.amount.toStringAsFixed(2)} 元';
    } else if (daysUntil == 1) {
      content = '您的定投计划将于明天执行，预计扣款 ${plan.amount.toStringAsFixed(2)} 元，请确保账户余额充足';
    } else {
      content = '您的定投计划将于 ${plan.nextExecuteDate!.toString().split(' ')[0]} 执行，预计扣款 ${plan.amount.toStringAsFixed(2)} 元';
    }
    
    return SipReminderMessage(
      title: '定投提醒',
      content: content,
      type: 'info',
      nextExecuteDate: plan.nextExecuteDate,
      amount: plan.amount,
    );
  }
  
  /// 获取所有需要提醒的定投计划
  static List<SipPlan> getPlansNeedReminder(List<SipPlan> plans) {
    final now = DateTime.now();
    return plans.where((plan) => shouldRemind(plan: plan, now: now)).toList();
  }
}

/// 定投提醒消息
class SipReminderMessage {
  final String title;
  final String content;
  final String type;
  final DateTime? nextExecuteDate;
  final double? amount;
  
  const SipReminderMessage({
    required this.title,
    required this.content,
    required this.type,
    this.nextExecuteDate,
    this.amount,
  });
}
