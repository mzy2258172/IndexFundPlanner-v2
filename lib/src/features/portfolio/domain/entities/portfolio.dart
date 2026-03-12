/// 投资组合实体
class Portfolio {
  final String id;
  final String name;
  final String description;
  final List<PortfolioItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  const Portfolio({
    required this.id,
    required this.name,
    this.description = '',
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });
  
  /// 总投资金额
  double get totalInvestment => 
      items.fold(0.0, (sum, item) => sum + item.investmentAmount);
  
  /// 总市值
  double get totalValue => 
      items.fold(0.0, (sum, item) => sum + item.currentValue);
  
  /// 总收益率
  double get totalReturnRate => 
      totalInvestment > 0 ? (totalValue - totalInvestment) / totalInvestment : 0;
  
  Portfolio copyWith({
    String? id,
    String? name,
    String? description,
    List<PortfolioItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Portfolio(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'items': items.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
  
  factory Portfolio.fromJson(Map<String, dynamic> json) => Portfolio(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    items: (json['items'] as List?)
      ?.map((e) => PortfolioItem.fromJson(e as Map<String, dynamic>))
      .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

/// 投资组合项目
class PortfolioItem {
  final String fundCode;
  final String fundName;
  final double investmentAmount;
  final double currentPrice;
  final double shares;
  final DateTime purchaseDate;
  
  const PortfolioItem({
    required this.fundCode,
    required this.fundName,
    required this.investmentAmount,
    required this.currentPrice,
    required this.shares,
    required this.purchaseDate,
  });
  
  /// 当前市值
  double get currentValue => currentPrice * shares;
  
  /// 收益率
  double get returnRate => 
      investmentAmount > 0 ? (currentValue - investmentAmount) / investmentAmount : 0;
  
  /// 收益金额
  double get profit => currentValue - investmentAmount;
  
  PortfolioItem copyWith({
    String? fundCode,
    String? fundName,
    double? investmentAmount,
    double? currentPrice,
    double? shares,
    DateTime? purchaseDate,
  }) {
    return PortfolioItem(
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      currentPrice: currentPrice ?? this.currentPrice,
      shares: shares ?? this.shares,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'fundName': fundName,
    'investmentAmount': investmentAmount,
    'currentPrice': currentPrice,
    'shares': shares,
    'purchaseDate': purchaseDate.toIso8601String(),
  };
  
  factory PortfolioItem.fromJson(Map<String, dynamic> json) => PortfolioItem(
    fundCode: json['fundCode'] as String,
    fundName: json['fundName'] as String,
    investmentAmount: (json['investmentAmount'] as num).toDouble(),
    currentPrice: (json['currentPrice'] as num).toDouble(),
    shares: (json['shares'] as num).toDouble(),
    purchaseDate: DateTime.parse(json['purchaseDate'] as String),
  );
}

/// 持仓统计信息
class PortfolioStats {
  final double totalInvestment;
  final double totalValue;
  final double totalProfit;
  final double totalReturnRate;
  final double todayProfit;
  final int itemCount;
  
  const PortfolioStats({
    required this.totalInvestment,
    required this.totalValue,
    required this.totalProfit,
    required this.totalReturnRate,
    required this.todayProfit,
    required this.itemCount,
  });
  
  factory PortfolioStats.empty() => const PortfolioStats(
    totalInvestment: 0,
    totalValue: 0,
    totalProfit: 0,
    totalReturnRate: 0,
    todayProfit: 0,
    itemCount: 0,
  );
}

/// 收益记录
class ProfitRecord {
  final DateTime date;
  final double profit;
  final double profitRate;
  
  const ProfitRecord({
    required this.date,
    required this.profit,
    required this.profitRate,
  });
}
