/// 用户实体
class User {
  final String id;
  final String phone;
  final String nickname;
  final String? avatarUrl;
  final RiskLevel riskLevel;
  final DateTime? riskAssessmentDate;
  final DateTime createdAt;
  
  const User({
    required this.id,
    required this.phone,
    required this.nickname,
    this.avatarUrl,
    this.riskLevel = RiskLevel.unknown,
    this.riskAssessmentDate,
    required this.createdAt,
  });
  
  User copyWith({
    String? id,
    String? phone,
    String? nickname,
    String? avatarUrl,
    RiskLevel? riskLevel,
    DateTime? riskAssessmentDate,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      riskLevel: riskLevel ?? this.riskLevel,
      riskAssessmentDate: riskAssessmentDate ?? this.riskAssessmentDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
    'nickname': nickname,
    'avatarUrl': avatarUrl,
    'riskLevel': riskLevel.index,
    'riskAssessmentDate': riskAssessmentDate?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
  };
  
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    phone: json['phone'] as String,
    nickname: json['nickname'] as String,
    avatarUrl: json['avatarUrl'] as String?,
    riskLevel: RiskLevel.values[json['riskLevel'] as int? ?? 0],
    riskAssessmentDate: json['riskAssessmentDate'] != null 
      ? DateTime.parse(json['riskAssessmentDate'] as String) 
      : null,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

/// 风险等级
enum RiskLevel {
  unknown,   // 未测评
  conservative,  // C1 保守型
  steady,    // C2 稳健型
  balanced,  // C3 平衡型
  aggressive,  // C4 进取型
  radical,   // C5 激进型
}

/// 风险等级扩展
extension RiskLevelExtension on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.unknown:
        return '未测评';
      case RiskLevel.conservative:
        return '保守型 (C1)';
      case RiskLevel.steady:
        return '稳健型 (C2)';
      case RiskLevel.balanced:
        return '平衡型 (C3)';
      case RiskLevel.aggressive:
        return '进取型 (C4)';
      case RiskLevel.radical:
        return '激进型 (C5)';
    }
  }
  
  String get shortName {
    switch (this) {
      case RiskLevel.unknown:
        return '未测评';
      case RiskLevel.conservative:
        return 'C1';
      case RiskLevel.steady:
        return 'C2';
      case RiskLevel.balanced:
        return 'C3';
      case RiskLevel.aggressive:
        return 'C4';
      case RiskLevel.radical:
        return 'C5';
    }
  }
  
  String get description {
    switch (this) {
      case RiskLevel.unknown:
        return '请完成风险评估以获取个性化推荐';
      case RiskLevel.conservative:
        return '推荐低风险产品，以稳健收益为主';
      case RiskLevel.steady:
        return '推荐中低风险产品，追求稳定增长';
      case RiskLevel.balanced:
        return '推荐均衡配置，平衡收益与风险';
      case RiskLevel.aggressive:
        return '推荐中高风险产品，追求较高收益';
      case RiskLevel.radical:
        return '推荐高风险产品，追求高收益';
    }
  }
}

/// 风险测评结果
class RiskAssessment {
  final String id;
  final String userId;
  final List<RiskAnswer> answers;
  final int totalScore;
  final RiskLevel riskLevel;
  final DateTime assessedAt;
  
  const RiskAssessment({
    required this.id,
    required this.userId,
    required this.answers,
    required this.totalScore,
    required this.riskLevel,
    required this.assessedAt,
  });
  
  /// 根据分数计算风险等级
  static RiskLevel calculateRiskLevel(int score) {
    if (score >= 80) return RiskLevel.radical;
    if (score >= 60) return RiskLevel.aggressive;
    if (score >= 40) return RiskLevel.balanced;
    if (score >= 20) return RiskLevel.steady;
    return RiskLevel.conservative;
  }
}

/// 风险测评答案
class RiskAnswer {
  final int questionIndex;
  final int answerIndex;
  final int score;
  
  const RiskAnswer({
    required this.questionIndex,
    required this.answerIndex,
    required this.score,
  });
}

/// 风险测评问题
class RiskQuestion {
  final int index;
  final String question;
  final List<RiskOption> options;
  final String category;
  final int weight;
  
  const RiskQuestion({
    required this.index,
    required this.question,
    required this.options,
    required this.category,
    this.weight = 1,
  });
}

/// 风险测评选项
class RiskOption {
  final int index;
  final String text;
  final int score;
  
  const RiskOption({
    required this.index,
    required this.text,
    required this.score,
  });
}
