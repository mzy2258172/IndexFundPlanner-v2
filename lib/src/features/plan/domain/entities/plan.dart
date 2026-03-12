/// 投资目标类型
enum PlanGoalType {
  education,    // 教育金
  retirement,   // 养老金
  house,        // 购房
  wedding,      // 结婚
  wealth,       // 财富增值
  custom,       // 自定义
}

extension PlanGoalTypeExtension on PlanGoalType {
  String get displayName {
    switch (this) {
      case PlanGoalType.education:
        return '教育金';
      case PlanGoalType.retirement:
        return '养老金';
      case PlanGoalType.house:
        return '购房首付';
      case PlanGoalType.wedding:
        return '结婚基金';
      case PlanGoalType.wealth:
        return '财富增值';
      case PlanGoalType.custom:
        return '自定义';
    }
  }
  
  String get emoji {
    switch (this) {
      case PlanGoalType.education:
        return '📚';
      case PlanGoalType.retirement:
        return '🎓';
      case PlanGoalType.house:
        return '🏠';
      case PlanGoalType.wedding:
        return '💒';
      case PlanGoalType.wealth:
        return '💰';
      case PlanGoalType.custom:
        return '✏️';
    }
  }
  
  String get description {
    switch (this) {
      case PlanGoalType.education:
        return '为孩子教育提前储备';
      case PlanGoalType.retirement:
        return '为退休生活做准备';
      case PlanGoalType.house:
        return '积累购房首付资金';
      case PlanGoalType.wedding:
        return '为结婚做准备';
      case PlanGoalType.wealth:
        return '让资产稳健增长';
      case PlanGoalType.custom:
        return '设定专属投资目标';
    }
  }
}

/// 投资计划实体
class InvestmentPlan {
  final String id;
  final String userId;
  final String name;
  final PlanGoalType goalType;
  final double targetAmount;      // 目标金额
  final double initialCapital;    // 初始本金
  final double currentAmount;     // 当前金额
  final DateTime startDate;       // 开始日期
  final DateTime targetDate;      // 目标日期
  final double monthlyInvestment; // 月投入金额
  final PlanStatus status;
  final Portfolio? portfolio;     // 关联的投资组合
  final SipPlan? sipPlan;         // 定投计划
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const InvestmentPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.goalType,
    required this.targetAmount,
    this.initialCapital = 0,
    this.currentAmount = 0,
    required this.startDate,
    required this.targetDate,
    required this.monthlyInvestment,
    this.status = PlanStatus.active,
    this.portfolio,
    this.sipPlan,
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// 计算进度
  double get progress => currentAmount / targetAmount;
  
  /// 计算剩余月数
  int get remainingMonths {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) return 0;
    return targetDate.difference(now).inDays ~/ 30;
  }
  
  /// 计算预计达成率
  double calculateExpectedProgress(double annualReturn) {
    final months = remainingMonths;
    final monthlyReturn = annualReturn / 12;
    
    // 初始本金复利终值
    final fvInitial = initialCapital * (1 + monthlyReturn) * months;
    
    // 定投复利终值
    final fvSip = monthlyInvestment * months * (1 + monthlyReturn / 2);
    
    return (currentAmount + fvInitial + fvSip) / targetAmount;
  }
  
  InvestmentPlan copyWith({
    String? id,
    String? userId,
    String? name,
    PlanGoalType? goalType,
    double? targetAmount,
    double? initialCapital,
    double? currentAmount,
    DateTime? startDate,
    DateTime? targetDate,
    double? monthlyInvestment,
    PlanStatus? status,
    Portfolio? portfolio,
    SipPlan? sipPlan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestmentPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      goalType: goalType ?? this.goalType,
      targetAmount: targetAmount ?? this.targetAmount,
      initialCapital: initialCapital ?? this.initialCapital,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      monthlyInvestment: monthlyInvestment ?? this.monthlyInvestment,
      status: status ?? this.status,
      portfolio: portfolio ?? this.portfolio,
      sipPlan: sipPlan ?? this.sipPlan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'goalType': goalType.index,
    'targetAmount': targetAmount,
    'initialCapital': initialCapital,
    'currentAmount': currentAmount,
    'startDate': startDate.toIso8601String(),
    'targetDate': targetDate.toIso8601String(),
    'monthlyInvestment': monthlyInvestment,
    'status': status.index,
    'portfolio': portfolio?.toJson(),
    'sipPlan': sipPlan?.toJson(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory InvestmentPlan.fromJson(Map<String, dynamic> json) => InvestmentPlan(
    id: json['id'] as String,
    userId: json['userId'] as String,
    name: json['name'] as String,
    goalType: PlanGoalType.values[json['goalType'] as int],
    targetAmount: (json['targetAmount'] as num).toDouble(),
    initialCapital: (json['initialCapital'] as num?)?.toDouble() ?? 0,
    currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0,
    startDate: DateTime.parse(json['startDate'] as String),
    targetDate: DateTime.parse(json['targetDate'] as String),
    monthlyInvestment: (json['monthlyInvestment'] as num).toDouble(),
    status: PlanStatus.values[json['status'] as int? ?? 0],
    portfolio: json['portfolio'] != null 
      ? Portfolio.fromJson(json['portfolio'] as Map<String, dynamic>) 
      : null,
    sipPlan: json['sipPlan'] != null 
      ? SipPlan.fromJson(json['sipPlan'] as Map<String, dynamic>) 
      : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// 计划状态
enum PlanStatus {
  active,     // 进行中
  completed,  // 已完成
  paused,     // 已暂停
  terminated, // 已终止
}

/// 投资组合
class Portfolio {
  final String id;
  final String name;
  final String type;  // recommended/custom
  final List<PortfolioAllocation> allocations;
  final double totalAmount;
  final double? expectedReturnMin;
  final double? expectedReturnMax;
  final int riskLevel;
  
  const Portfolio({
    required this.id,
    required this.name,
    required this.type,
    required this.allocations,
    this.totalAmount = 0,
    this.expectedReturnMin,
    this.expectedReturnMax,
    required this.riskLevel,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'allocations': allocations.map((a) => a.toJson()).toList(),
    'totalAmount': totalAmount,
    'expectedReturnMin': expectedReturnMin,
    'expectedReturnMax': expectedReturnMax,
    'riskLevel': riskLevel,
  };
  
  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    allocations: (json['allocations'] as List)
      .map((a) => PortfolioAllocation.fromJson(a as Map<String, dynamic>))
      .toList(),
    totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
    expectedReturnMin: (json['expectedReturnMin'] as num?)?.toDouble(),
    expectedReturnMax: (json['expectedReturnMax'] as num?)?.toDouble(),
    riskLevel: json['riskLevel'] as int,
  );
}

/// 组合配置
class PortfolioAllocation {
  final String fundCode;
  final String fundName;
  final double ratio;  // 配置比例
  final double? amount;
  
  const PortfolioAllocation({
    required this.fundCode,
    required this.fundName,
    required this.ratio,
    this.amount,
  });
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'fundName': fundName,
    'ratio': ratio,
    'amount': amount,
  };
  
  factory PortfolioAllocation.fromJson(Map<String, dynamic> json) => 
    PortfolioAllocation(
      fundCode: json['fundCode'] as String,
      fundName: json['fundName'] as String,
      ratio: (json['ratio'] as num).toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
    );
}

/// 定投计划
class SipPlan {
  final String id;
  final String frequency;  // weekly/biweekly/monthly
  final int investmentDay; // 扣款日 (1-28)
  final double amount;
  final String strategy;   // normal/ma/value_avg
  final SipStatus status;
  final DateTime? nextExecuteDate;
  final double totalInvested;
  
  const SipPlan({
    required this.id,
    required this.frequency,
    required this.investmentDay,
    required this.amount,
    this.strategy = 'normal',
    this.status = SipStatus.active,
    this.nextExecuteDate,
    this.totalInvested = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'frequency': frequency,
    'investmentDay': investmentDay,
    'amount': amount,
    'strategy': strategy,
    'status': status.index,
    'nextExecuteDate': nextExecuteDate?.toIso8601String(),
    'totalInvested': totalInvested,
  };
  
  factory SipPlan.fromJson(Map<String, dynamic> json) => SipPlan(
    id: json['id'] as String,
    frequency: json['frequency'] as String,
    investmentDay: json['investmentDay'] as int,
    amount: (json['amount'] as num).toDouble(),
    strategy: json['strategy'] as String? ?? 'normal',
    status: SipStatus.values[json['status'] as int? ?? 0],
    nextExecuteDate: json['nextExecuteDate'] != null 
      ? DateTime.parse(json['nextExecuteDate'] as String) 
      : null,
    totalInvested: (json['totalInvested'] as num?)?.toDouble() ?? 0,
  );
}

/// 定投状态
enum SipStatus {
  active,
  paused,
  terminated,
}
