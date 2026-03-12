import '../entities/user.dart';
import '../entities/risk_questions.dart';

/// 风险评估服务 - 处理风险测评的核心业务逻辑
class RiskAssessmentService {
  /// 10道标准问卷题目（从 risk_questions.dart 导入）
  List<RiskQuestion> getQuestions() => riskQuestions;
  
  /// 计算风险测评总分
  /// 每道题的分数根据选项确定
  int calculateTotalScore(List<RiskAnswer> answers) {
    int totalScore = 0;
    
    for (final answer in answers) {
      final question = riskQuestions[answer.questionIndex];
      if (answer.answerIndex < question.options.length) {
        totalScore += question.options[answer.answerIndex].score;
      }
    }
    
    return totalScore;
  }
  
  /// 根据总分计算风险等级
  /// C1 保守型：0-25分
  /// C2 稳健型：26-45分
  /// C3 平衡型：46-65分
  /// C4 进取型：66-85分
  /// C5 激进型：86分以上
  RiskLevel calculateRiskLevel(int totalScore) {
    if (totalScore >= 86) {
      return RiskLevel.radical;
    } else if (totalScore >= 66) {
      return RiskLevel.aggressive;
    } else if (totalScore >= 46) {
      return RiskLevel.balanced;
    } else if (totalScore >= 26) {
      return RiskLevel.steady;
    } else {
      return RiskLevel.conservative;
    }
  }
  
  /// 执行风险评估
  /// 返回完整的评估结果
  RiskAssessmentResult assess(String userId, Map<int, int> answers) {
    // 转换答案格式
    final answerList = answers.entries.map((entry) {
      final questionIndex = entry.key;
      final answerIndex = entry.value;
      final question = riskQuestions[questionIndex];
      final score = question.options[answerIndex].score;
      
      return RiskAnswer(
        questionIndex: questionIndex,
        answerIndex: answerIndex,
        score: score,
      );
    }).toList();
    
    // 计算总分
    final totalScore = calculateTotalScore(answerList);
    
    // 计算风险等级
    final riskLevel = calculateRiskLevel(totalScore);
    
    // 计算各维度得分
    final dimensionScores = _calculateDimensionScores(answerList);
    
    // 生成评估报告
    final report = _generateReport(riskLevel, totalScore, dimensionScores);
    
    return RiskAssessmentResult(
      userId: userId,
      answers: answerList,
      totalScore: totalScore,
      riskLevel: riskLevel,
      dimensionScores: dimensionScores,
      report: report,
    );
  }
  
  /// 计算各维度得分
  Map<String, int> _calculateDimensionScores(List<RiskAnswer> answers) {
    final dimensions = <String, int>{};
    
    for (final answer in answers) {
      final question = riskQuestions[answer.questionIndex];
      final category = question.category;
      final score = question.options[answer.answerIndex].score;
      
      dimensions[category] = (dimensions[category] ?? 0) + score;
    }
    
    return dimensions;
  }
  
  /// 生成评估报告
  String _generateReport(
    RiskLevel riskLevel,
    int totalScore,
    Map<String, int> dimensionScores,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 风险评估报告 ===');
    buffer.writeln();
    buffer.writeln('风险类型：${riskLevel.displayName}');
    buffer.writeln('评估得分：$totalScore 分');
    buffer.writeln();
    buffer.writeln('各维度得分：');
    
    dimensionScores.forEach((dimension, score) {
      buffer.writeln('  - $dimension: $score 分');
    });
    
    buffer.writeln();
    buffer.writeln('投资建议：');
    buffer.writeln(riskLevel.description);
    
    return buffer.toString();
  }
  
  /// 验证答案是否完整
  /// 返回缺失的题目索引列表
  List<int> validateAnswers(Map<int, int> answers) {
    final missing = <int>[];
    
    for (int i = 0; i < riskQuestions.length; i++) {
      if (!answers.containsKey(i)) {
        missing.add(i);
      }
    }
    
    return missing;
  }
  
  /// 获取风险等级对应的投资建议
  InvestmentAdvice getInvestmentAdvice(RiskLevel riskLevel) {
    switch (riskLevel) {
      case RiskLevel.unknown:
        return InvestmentAdvice(
          title: '请先完成风险评估',
          description: '完成风险评估后，我们将为您提供个性化的投资建议',
          recommendedAllocation: {},
          maxRiskLevel: 0,
        );
        
      case RiskLevel.conservative:
        return InvestmentAdvice(
          title: '保守型投资组合',
          description: '以稳健收益为主，主要配置低风险产品',
          recommendedAllocation: {
            '货币基金': 0.30,
            '债券基金': 0.50,
            '指数基金': 0.15,
            '股票基金': 0.05,
          },
          maxRiskLevel: 1,
        );
        
      case RiskLevel.steady:
        return InvestmentAdvice(
          title: '稳健型投资组合',
          description: '追求稳定增长，适度配置中低风险产品',
          recommendedAllocation: {
            '货币基金': 0.15,
            '债券基金': 0.35,
            '指数基金': 0.35,
            '股票基金': 0.15,
          },
          maxRiskLevel: 2,
        );
        
      case RiskLevel.balanced:
        return InvestmentAdvice(
          title: '平衡型投资组合',
          description: '均衡配置，平衡收益与风险',
          recommendedAllocation: {
            '货币基金': 0.10,
            '债券基金': 0.20,
            '指数基金': 0.40,
            '股票基金': 0.30,
          },
          maxRiskLevel: 3,
        );
        
      case RiskLevel.aggressive:
        return InvestmentAdvice(
          title: '进取型投资组合',
          description: '追求较高收益，可接受较大波动',
          recommendedAllocation: {
            '货币基金': 0.05,
            '债券基金': 0.10,
            '指数基金': 0.35,
            '股票基金': 0.50,
          },
          maxRiskLevel: 4,
        );
        
      case RiskLevel.radical:
        return InvestmentAdvice(
          title: '激进型投资组合',
          description: '追求高收益，可承受较大回撤',
          recommendedAllocation: {
            '货币基金': 0.00,
            '债券基金': 0.05,
            '指数基金': 0.30,
            '股票基金': 0.65,
          },
          maxRiskLevel: 5,
        );
    }
  }
  
  /// 检查风险测评是否需要重测
  /// 根据监管要求，风险测评有效期为18个月
  bool needsReassessment(DateTime? lastAssessmentDate) {
    if (lastAssessmentDate == null) return true;
    
    final monthsSince = DateTime.now().difference(lastAssessmentDate).inDays ~/ 30;
    return monthsSince >= 18;
  }
  
  /// 计算风险测评剩余有效期（月）
  int remainingValidityMonths(DateTime? lastAssessmentDate) {
    if (lastAssessmentDate == null) return 0;
    
    final monthsSince = DateTime.now().difference(lastAssessmentDate).inDays ~/ 30;
    final remaining = 18 - monthsSince;
    return remaining > 0 ? remaining : 0;
  }
}

/// 风险评估结果
class RiskAssessmentResult {
  final String userId;
  final List<RiskAnswer> answers;
  final int totalScore;
  final RiskLevel riskLevel;
  final Map<String, int> dimensionScores;
  final String report;
  
  const RiskAssessmentResult({
    required this.userId,
    required this.answers,
    required this.totalScore,
    required this.riskLevel,
    required this.dimensionScores,
    required this.report,
  });
  
  /// 转换为 RiskAssessment 实体
  RiskAssessment toRiskAssessment(String id) {
    return RiskAssessment(
      id: id,
      userId: userId,
      answers: answers,
      totalScore: totalScore,
      riskLevel: riskLevel,
      assessedAt: DateTime.now(),
    );
  }
}

/// 投资建议
class InvestmentAdvice {
  final String title;
  final String description;
  final Map<String, double> recommendedAllocation;
  final int maxRiskLevel;
  
  const InvestmentAdvice({
    required this.title,
    required this.description,
    required this.recommendedAllocation,
    required this.maxRiskLevel,
  });
}
