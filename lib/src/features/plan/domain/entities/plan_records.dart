import '../entities/plan.dart';

/// 定投执行记录
class SipExecution {
  final String id;
  final String sipPlanId;
  final DateTime executeDate;
  final double amount;
  final double nav;
  final double shares;
  final SipExecutionStatus status;
  final String? failReason;
  final DateTime createdAt;
  
  const SipExecution({
    required this.id,
    required this.sipPlanId,
    required this.executeDate,
    required this.amount,
    required this.nav,
    required this.shares,
    required this.status,
    this.failReason,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'sipPlanId': sipPlanId,
    'executeDate': executeDate.toIso8601String(),
    'amount': amount,
    'nav': nav,
    'shares': shares,
    'status': status.index,
    'failReason': failReason,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory SipExecution.fromJson(Map<String, dynamic> json) => SipExecution(
    id: json['id'] as String,
    sipPlanId: json['sipPlanId'] as String,
    executeDate: DateTime.parse(json['executeDate'] as String),
    amount: (json['amount'] as num).toDouble(),
    nav: (json['nav'] as num).toDouble(),
    shares: (json['shares'] as num).toDouble(),
    status: SipExecutionStatus.values[json['status'] as int? ?? 0],
    failReason: json['failReason'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// 定投执行状态
enum SipExecutionStatus {
  pending,    // 待执行
  success,    // 成功
  failed,     // 失败
}

/// 调仓记录
class RebalanceRecord {
  final String id;
  final String planId;
  final String portfolioId;
  final DateTime executeDate;
  final List<RebalanceTransaction> transactions;
  final double totalFee;
  final RebalanceStatus status;
  final String reason;
  final DateTime createdAt;
  
  const RebalanceRecord({
    required this.id,
    required this.planId,
    required this.portfolioId,
    required this.executeDate,
    required this.transactions,
    required this.totalFee,
    required this.status,
    required this.reason,
    required this.createdAt,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'portfolioId': portfolioId,
    'executeDate': executeDate.toIso8601String(),
    'transactions': transactions.map((t) => t.toJson()).toList(),
    'totalFee': totalFee,
    'status': status.index,
    'reason': reason,
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory RebalanceRecord.fromJson(Map<String, dynamic> json) => RebalanceRecord(
    id: json['id'] as String,
    planId: json['planId'] as String,
    portfolioId: json['portfolioId'] as String,
    executeDate: DateTime.parse(json['executeDate'] as String),
    transactions: (json['transactions'] as List)
      .map((t) => RebalanceTransaction.fromJson(t as Map<String, dynamic>))
      .toList(),
    totalFee: (json['totalFee'] as num).toDouble(),
    status: RebalanceStatus.values[json['status'] as int? ?? 0],
    reason: json['reason'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// 调仓交易
class RebalanceTransaction {
  final String fundCode;
  final String fundName;
  final String type;  // buy/sell
  final double amount;
  final double shares;
  final double nav;
  final double fee;
  
  const RebalanceTransaction({
    required this.fundCode,
    required this.fundName,
    required this.type,
    required this.amount,
    required this.shares,
    required this.nav,
    required this.fee,
  });
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'fundName': fundName,
    'type': type,
    'amount': amount,
    'shares': shares,
    'nav': nav,
    'fee': fee,
  };
  
  factory RebalanceTransaction.fromJson(Map<String, dynamic> json) => 
    RebalanceTransaction(
      fundCode: json['fundCode'] as String,
      fundName: json['fundName'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      shares: (json['shares'] as num).toDouble(),
      nav: (json['nav'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
    );
}

/// 调仓状态
enum RebalanceStatus {
  pending,    // 待执行
  completed,  // 已完成
  failed,     // 失败
}

/// 投资计划详细视图
class PlanDetailView {
  final InvestmentPlan plan;
  final Portfolio portfolio;
  final SipPlan? sipPlan;
  final List<SipExecution> sipExecutions;
  final List<RebalanceRecord> rebalanceRecords;
  final PlanProgress progress;
  final PlanRiskMetrics riskMetrics;
  
  const PlanDetailView({
    required this.plan,
    required this.portfolio,
    this.sipPlan,
    this.sipExecutions = const [],
    this.rebalanceRecords = const [],
    required this.progress,
    required this.riskMetrics,
  });
  
  Map<String, dynamic> toJson() => {
    'plan': plan.toJson(),
    'portfolio': portfolio.toJson(),
    'sipPlan': sipPlan?.toJson(),
    'sipExecutions': sipExecutions.map((e) => e.toJson()).toList(),
    'rebalanceRecords': rebalanceRecords.map((r) => r.toJson()).toList(),
    'progress': progress.toJson(),
    'riskMetrics': riskMetrics.toJson(),
  };
}

/// 计划进度
class PlanProgress {
  final double currentAmount;
  final double targetAmount;
  final double progressPercent;
  final int totalDays;
  final int passedDays;
  final int remainingDays;
  final double investedAmount;
  final double profitAmount;
  final double profitPercent;
  final double expectedFinalAmount;
  final double expectedProgressPercent;
  
  const PlanProgress({
    required this.currentAmount,
    required this.targetAmount,
    required this.progressPercent,
    required this.totalDays,
    required this.passedDays,
    required this.remainingDays,
    required this.investedAmount,
    required this.profitAmount,
    required this.profitPercent,
    required this.expectedFinalAmount,
    required this.expectedProgressPercent,
  });
  
  bool get isOnTrack => expectedProgressPercent >= progressPercent;
  
  String get progressStatus {
    if (progressPercent >= 100) return '已完成';
    if (isOnTrack) return '进度正常';
    return '进度落后';
  }
  
  Map<String, dynamic> toJson() => {
    'currentAmount': currentAmount,
    'targetAmount': targetAmount,
    'progressPercent': progressPercent,
    'totalDays': totalDays,
    'passedDays': passedDays,
    'remainingDays': remainingDays,
    'investedAmount': investedAmount,
    'profitAmount': profitAmount,
    'profitPercent': profitPercent,
    'expectedFinalAmount': expectedFinalAmount,
    'expectedProgressPercent': expectedProgressPercent,
    'isOnTrack': isOnTrack,
    'progressStatus': progressStatus,
  };
}

/// 计划风险指标
class PlanRiskMetrics {
  final double volatility;
  final double maxDrawdown;
  final double sharpeRatio;
  final double beta;
  final double alpha;
  final String riskLevel;
  final String riskWarning;
  
  const PlanRiskMetrics({
    required this.volatility,
    required this.maxDrawdown,
    required this.sharpeRatio,
    this.beta = 1.0,
    this.alpha = 0,
    required this.riskLevel,
    required this.riskWarning,
  });
  
  Map<String, dynamic> toJson() => {
    'volatility': volatility,
    'maxDrawdown': maxDrawdown,
    'sharpeRatio': sharpeRatio,
    'beta': beta,
    'alpha': alpha,
    'riskLevel': riskLevel,
    'riskWarning': riskWarning,
  };
}
