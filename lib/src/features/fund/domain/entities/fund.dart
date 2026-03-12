/// 基金实体
class Fund {
  final String code;
  final String name;
  final String type;
  final double currentPrice;
  final double dayChange;
  final double dayChangeRate;
  final DateTime updatedAt;
  
  // 扩展字段
  final String? fundCompany;
  final double? scale;
  final double? managementFee;
  final double? custodyFee;
  final int? riskLevel;
  final DateTime? establishDate;
  final String? trackingIndex;
  final double? return1y;   // 近1年收益率
  final double? return3y;   // 近3年收益率
  final double? return5y;   // 近5年收益率
  final double? maxDrawdown;
  final double? sharpeRatio;
  
  const Fund({
    required this.code,
    required this.name,
    required this.type,
    required this.currentPrice,
    this.dayChange = 0,
    this.dayChangeRate = 0,
    required this.updatedAt,
    this.fundCompany,
    this.scale,
    this.managementFee,
    this.custodyFee,
    this.riskLevel,
    this.establishDate,
    this.trackingIndex,
    this.return1y,
    this.return3y,
    this.return5y,
    this.maxDrawdown,
    this.sharpeRatio,
  });
  
  Fund copyWith({
    String? code,
    String? name,
    String? type,
    double? currentPrice,
    double? dayChange,
    double? dayChangeRate,
    DateTime? updatedAt,
    String? fundCompany,
    double? scale,
    double? managementFee,
    double? custodyFee,
    int? riskLevel,
    DateTime? establishDate,
    String? trackingIndex,
    double? return1y,
    double? return3y,
    double? return5y,
    double? maxDrawdown,
    double? sharpeRatio,
  }) {
    return Fund(
      code: code ?? this.code,
      name: name ?? this.name,
      type: type ?? this.type,
      currentPrice: currentPrice ?? this.currentPrice,
      dayChange: dayChange ?? this.dayChange,
      dayChangeRate: dayChangeRate ?? this.dayChangeRate,
      updatedAt: updatedAt ?? this.updatedAt,
      fundCompany: fundCompany ?? this.fundCompany,
      scale: scale ?? this.scale,
      managementFee: managementFee ?? this.managementFee,
      custodyFee: custodyFee ?? this.custodyFee,
      riskLevel: riskLevel ?? this.riskLevel,
      establishDate: establishDate ?? this.establishDate,
      trackingIndex: trackingIndex ?? this.trackingIndex,
      return1y: return1y ?? this.return1y,
      return3y: return3y ?? this.return3y,
      return5y: return5y ?? this.return5y,
      maxDrawdown: maxDrawdown ?? this.maxDrawdown,
      sharpeRatio: sharpeRatio ?? this.sharpeRatio,
    );
  }
  
  /// 获取风险等级名称
  String get riskLevelName {
    switch (riskLevel) {
      case 1:
        return '低风险';
      case 2:
        return '中低风险';
      case 3:
        return '中风险';
      case 4:
        return '中高风险';
      case 5:
        return '高风险';
      default:
        return '未知';
    }
  }
  
  /// 是否为指数基金
  bool get isIndexFund => 
    type.contains('指数') || 
    type.contains('ETF') || 
    type.contains('LOF');
  
  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'type': type,
    'currentPrice': currentPrice,
    'dayChange': dayChange,
    'dayChangeRate': dayChangeRate,
    'updatedAt': updatedAt.toIso8601String(),
    'fundCompany': fundCompany,
    'scale': scale,
    'managementFee': managementFee,
    'custodyFee': custodyFee,
    'riskLevel': riskLevel,
    'establishDate': establishDate?.toIso8601String(),
    'trackingIndex': trackingIndex,
    'return1y': return1y,
    'return3y': return3y,
    'return5y': return5y,
    'maxDrawdown': maxDrawdown,
    'sharpeRatio': sharpeRatio,
  };
  
  factory Fund.fromJson(Map<String, dynamic> json) => Fund(
    code: json['code'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0,
    dayChange: (json['dayChange'] as num?)?.toDouble() ?? 0,
    dayChangeRate: (json['dayChangeRate'] as num?)?.toDouble() ?? 0,
    updatedAt: json['updatedAt'] != null 
      ? DateTime.parse(json['updatedAt'] as String) 
      : DateTime.now(),
    fundCompany: json['fundCompany'] as String?,
    scale: (json['scale'] as num?)?.toDouble(),
    managementFee: (json['managementFee'] as num?)?.toDouble(),
    custodyFee: (json['custodyFee'] as num?)?.toDouble(),
    riskLevel: json['riskLevel'] as int?,
    establishDate: json['establishDate'] != null 
      ? DateTime.parse(json['establishDate'] as String) 
      : null,
    trackingIndex: json['trackingIndex'] as String?,
    return1y: (json['return1y'] as num?)?.toDouble(),
    return3y: (json['return3y'] as num?)?.toDouble(),
    return5y: (json['return5y'] as num?)?.toDouble(),
    maxDrawdown: (json['maxDrawdown'] as num?)?.toDouble(),
    sharpeRatio: (json['sharpeRatio'] as num?)?.toDouble(),
  );
  
  @override
  String toString() => 'Fund($code: $name)';
}

/// 基金详情（扩展信息）
class FundDetail {
  final Fund fund;
  final List<FundNetValue> netValueHistory;
  final List<FundHolding>? holdings;
  final FundManager? manager;
  final String? prospectus;
  final String? announcement;
  
  const FundDetail({
    required this.fund,
    this.netValueHistory = const [],
    this.holdings,
    this.manager,
    this.prospectus,
    this.announcement,
  });
  
  /// 获取近N日收益率
  double? getReturn(int days) {
    if (netValueHistory.length < days) return null;
    final latest = netValueHistory.first.netValue;
    final past = netValueHistory[days - 1].netValue;
    if (past == 0) return null;
    return ((latest - past) / past) * 100;
  }
  
  /// 获取最大回撤
  double? calculateMaxDrawdown() {
    if (netValueHistory.isEmpty) return null;
    
    double maxDrawdown = 0;
    double maxValue = netValueHistory.first.netValue;
    
    for (final item in netValueHistory) {
      if (item.netValue > maxValue) {
        maxValue = item.netValue;
      }
      final drawdown = (maxValue - item.netValue) / maxValue;
      if (drawdown > maxDrawdown) {
        maxDrawdown = drawdown;
      }
    }
    
    return maxDrawdown * 100;
  }
  
  Map<String, dynamic> toJson() => {
    'fund': fund.toJson(),
    'netValueHistory': netValueHistory.map((e) => e.toJson()).toList(),
    'holdings': holdings?.map((e) => e.toJson()).toList(),
    'manager': manager?.toJson(),
    'prospectus': prospectus,
    'announcement': announcement,
  };
  
  factory FundDetail.fromJson(Map<String, dynamic> json) => FundDetail(
    fund: Fund.fromJson(json['fund'] as Map<String, dynamic>),
    netValueHistory: (json['netValueHistory'] as List?)
      ?.map((e) => FundNetValue.fromJson(e as Map<String, dynamic>))
      .toList() ?? [],
    holdings: (json['holdings'] as List?)
      ?.map((e) => FundHolding.fromJson(e as Map<String, dynamic>))
      .toList(),
    manager: json['manager'] != null 
      ? FundManager.fromJson(json['manager'] as Map<String, dynamic>) 
      : null,
    prospectus: json['prospectus'] as String?,
    announcement: json['announcement'] as String?,
  );
}

/// 基金净值历史
class FundNetValue {
  final String fundCode;
  final DateTime date;
  final double netValue;
  final double cumulativeValue;
  final double? dayChangeRate;
  
  const FundNetValue({
    required this.fundCode,
    required this.date,
    required this.netValue,
    required this.cumulativeValue,
    this.dayChangeRate,
  });
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'date': date.toIso8601String(),
    'netValue': netValue,
    'cumulativeValue': cumulativeValue,
    'dayChangeRate': dayChangeRate,
  };
  
  factory FundNetValue.fromJson(Map<String, dynamic> json) => FundNetValue(
    fundCode: json['fundCode'] as String,
    date: DateTime.parse(json['date'] as String),
    netValue: (json['netValue'] as num).toDouble(),
    cumulativeValue: (json['cumulativeValue'] as num).toDouble(),
    dayChangeRate: (json['dayChangeRate'] as num?)?.toDouble(),
  );
  
  @override
  String toString() => 'FundNetValue($fundCode, $date: $netValue)';
}

/// 基金持仓
class FundHolding {
  final String stockCode;
  final String stockName;
  final double ratio;
  final double shares;
  final double value;
  
  const FundHolding({
    required this.stockCode,
    required this.stockName,
    required this.ratio,
    required this.shares,
    required this.value,
  });
  
  Map<String, dynamic> toJson() => {
    'stockCode': stockCode,
    'stockName': stockName,
    'ratio': ratio,
    'shares': shares,
    'value': value,
  };
  
  factory FundHolding.fromJson(Map<String, dynamic> json) => FundHolding(
    stockCode: json['stockCode'] as String,
    stockName: json['stockName'] as String,
    ratio: (json['ratio'] as num).toDouble(),
    shares: (json['shares'] as num).toDouble(),
    value: (json['value'] as num).toDouble(),
  );
}

/// 基金经理
class FundManager {
  final String name;
  final DateTime? startDate;
  final double? totalAsset;
  final double? bestReturn;
  final String? photo;
  
  const FundManager({
    required this.name,
    this.startDate,
    this.totalAsset,
    this.bestReturn,
    this.photo,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'startDate': startDate?.toIso8601String(),
    'totalAsset': totalAsset,
    'bestReturn': bestReturn,
    'photo': photo,
  };
  
  factory FundManager.fromJson(Map<String, dynamic> json) => FundManager(
    name: json['name'] as String,
    startDate: json['startDate'] != null 
      ? DateTime.parse(json['startDate'] as String) 
      : null,
    totalAsset: (json['totalAsset'] as num?)?.toDouble(),
    bestReturn: (json['bestReturn'] as num?)?.toDouble(),
    photo: json['photo'] as String?,
  );
}

/// 缓存的基金列表
class CachedFundList {
  final List<Fund> funds;
  final DateTime cachedAt;
  final String cacheKey;
  
  const CachedFundList({
    required this.funds,
    required this.cachedAt,
    required this.cacheKey,
  });
  
  /// 是否过期（默认24小时）
  bool isExpired({Duration maxAge = const Duration(hours: 24)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
  
  Map<String, dynamic> toJson() => {
    'funds': funds.map((e) => e.toJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
    'cacheKey': cacheKey,
  };
  
  factory CachedFundList.fromJson(Map<String, dynamic> json) => CachedFundList(
    funds: (json['funds'] as List)
      .map((e) => Fund.fromJson(e as Map<String, dynamic>))
      .toList(),
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    cacheKey: json['cacheKey'] as String,
  );
}

/// 缓存的基金详情
class CachedFundDetail {
  final FundDetail detail;
  final DateTime cachedAt;
  
  const CachedFundDetail({
    required this.detail,
    required this.cachedAt,
  });
  
  /// 是否过期（默认1小时，详情更新更频繁）
  bool isExpired({Duration maxAge = const Duration(hours: 1)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
  
  Map<String, dynamic> toJson() => {
    'detail': detail.toJson(),
    'cachedAt': cachedAt.toIso8601String(),
  };
  
  factory CachedFundDetail.fromJson(Map<String, dynamic> json) => CachedFundDetail(
    detail: FundDetail.fromJson(json['detail'] as Map<String, dynamic>),
    cachedAt: DateTime.parse(json['cachedAt'] as String),
  );
}

/// 缓存的净值历史
class CachedNetValueHistory {
  final String fundCode;
  final List<FundNetValue> history;
  final DateTime cachedAt;
  final int requestedDays;
  
  const CachedNetValueHistory({
    required this.fundCode,
    required this.history,
    required this.cachedAt,
    required this.requestedDays,
  });
  
  /// 是否过期（默认6小时）
  bool isExpired({Duration maxAge = const Duration(hours: 6)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
  
  /// 是否覆盖请求的天数
  bool coversRequest(int days) {
    return history.length >= days && !isExpired();
  }
  
  Map<String, dynamic> toJson() => {
    'fundCode': fundCode,
    'history': history.map((e) => e.toJson()).toList(),
    'cachedAt': cachedAt.toIso8601String(),
    'requestedDays': requestedDays,
  };
  
  factory CachedNetValueHistory.fromJson(Map<String, dynamic> json) => CachedNetValueHistory(
    fundCode: json['fundCode'] as String,
    history: (json['history'] as List)
      .map((e) => FundNetValue.fromJson(e as Map<String, dynamic>))
      .toList(),
    cachedAt: DateTime.parse(json['cachedAt'] as String),
    requestedDays: json['requestedDays'] as int,
  );
}
