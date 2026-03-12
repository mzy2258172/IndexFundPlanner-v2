import 'package:flutter_test/flutter_test.dart';
import 'package:index_fund_planner/src/features/user/domain/entities/user.dart';
import 'package:index_fund_planner/src/features/user/domain/entities/risk_questions.dart';
import 'package:index_fund_planner/src/features/user/domain/services/risk_assessment_service.dart';
import 'package:index_fund_planner/src/features/user/data/services/auth_service.dart';

void main() {
  group('AuthService Tests', () {
    final authService = AuthService();
    
    test('Valid phone number should pass validation', () {
      expect(authService.isValidPhoneNumber('13800138000'), isTrue);
      expect(authService.isValidPhoneNumber('15912345678'), isTrue);
      expect(authService.isValidPhoneNumber('18888888888'), isTrue);
    });
    
    test('Invalid phone number should fail validation', () {
      expect(authService.isValidPhoneNumber('12345678901'), isFalse); // Wrong prefix
      expect(authService.isValidPhoneNumber('1380013800'), isFalse);  // Too short
      expect(authService.isValidPhoneNumber('138001380001'), isFalse); // Too long
      expect(authService.isValidPhoneNumber('abc12345678'), isFalse);  // Non-numeric
    });
    
    test('Send verification code should succeed for valid phone', () async {
      final result = await authService.sendVerificationCode('13800138000');
      expect(result.success, isTrue);
      expect(result.code, isNotNull);
      expect(result.code!.length, equals(6));
    });
    
    test('Send verification code should fail for invalid phone', () async {
      final result = await authService.sendVerificationCode('12345');
      expect(result.success, isFalse);
      expect(result.errorMessage, isNotNull);
    });
    
    test('Verify code should succeed for correct code', () async {
      final sendResult = await authService.sendVerificationCode('13800138001');
      expect(sendResult.success, isTrue);
      
      final verifyResult = authService.verifyCode('13800138001', sendResult.code!);
      expect(verifyResult.success, isTrue);
    });
    
    test('Verify code should fail for wrong code', () async {
      await authService.sendVerificationCode('13800138002');
      final verifyResult = authService.verifyCode('13800138002', '000000');
      expect(verifyResult.success, isFalse);
    });
  });
  
  group('RiskAssessmentService Tests', () {
    final riskService = RiskAssessmentService();
    
    test('Should have 10 risk questions', () {
      expect(riskService.getQuestions().length, equals(10));
    });
    
    test('Calculate total score correctly', () {
      // 选择所有最低风险选项
      final conservativeAnswers = {
        0: 4,  // 60岁以上，0分
        1: 0,  // 无投资经验，0分
        2: 0,  // 仅银行存款，0分
        3: 0,  // 10万以下，2分
        4: 0,  // 10万以下，1分
        5: 3,  // 50-70%，1分
        6: 0,  // 保本，0分
        7: 0,  // 1年以内，0分
        8: 0,  // 全部卖出，0分
        9: 0,  // 2-4%收益，0分
      };
      
      final result = riskService.assess('test_user', conservativeAnswers);
      expect(result.riskLevel, equals(RiskLevel.conservative));
    });
    
    test('Calculate total score for aggressive investor', () {
      // 选择所有高风险选项
      final aggressiveAnswers = {
        0: 0,  // 30岁以下，15分
        1: 4,  // 5年以上，10分
        2: 4,  // 期货期权，12分
        3: 4,  // 100万以上，15分
        4: 4,  // 300万以上，10分
        5: 0,  // 10%以下，7分
        6: 3,  // 高收益，10分
        7: 3,  // 5年以上，8分
        8: 3,  // 加仓，10分
        9: 3,  // >15%收益，12分
      };
      
      final result = riskService.assess('test_user', aggressiveAnswers);
      expect(result.riskLevel, equals(RiskLevel.radical));
    });
    
    test('Risk level calculation matches score ranges', () {
      expect(riskService.calculateRiskLevel(0), equals(RiskLevel.conservative));
      expect(riskService.calculateRiskLevel(25), equals(RiskLevel.conservative));
      expect(riskService.calculateRiskLevel(26), equals(RiskLevel.steady));
      expect(riskService.calculateRiskLevel(45), equals(RiskLevel.steady));
      expect(riskService.calculateRiskLevel(46), equals(RiskLevel.balanced));
      expect(riskService.calculateRiskLevel(65), equals(RiskLevel.balanced));
      expect(riskService.calculateRiskLevel(66), equals(RiskLevel.aggressive));
      expect(riskService.calculateRiskLevel(85), equals(RiskLevel.aggressive));
      expect(riskService.calculateRiskLevel(86), equals(RiskLevel.radical));
      expect(riskService.calculateRiskLevel(100), equals(RiskLevel.radical));
    });
    
    test('Validate incomplete answers', () {
      final incompleteAnswers = {0: 0, 1: 1, 2: 2}; // Only 3 of 10 questions
      final missing = riskService.validateAnswers(incompleteAnswers);
      expect(missing.length, equals(7));
      expect(missing.contains(3), isTrue);
      expect(missing.contains(9), isTrue);
    });
    
    test('Investment advice for each risk level', () {
      final conservativeAdvice = riskService.getInvestmentAdvice(RiskLevel.conservative);
      expect(conservativeAdvice.maxRiskLevel, equals(1));
      expect(conservativeAdvice.recommendedAllocation.containsKey('货币基金'), isTrue);
      
      final radicalAdvice = riskService.getInvestmentAdvice(RiskLevel.radical);
      expect(radicalAdvice.maxRiskLevel, equals(5));
      expect(radicalAdvice.recommendedAllocation['股票基金'], greaterThan(0.5));
    });
    
    test('Needs reassessment check', () {
      // 18个月前
      final oldDate = DateTime.now().subtract(const Duration(days: 540));
      expect(riskService.needsReassessment(oldDate), isTrue);
      
      // 1个月前
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      expect(riskService.needsReassessment(recentDate), isFalse);
      
      // null
      expect(riskService.needsReassessment(null), isTrue);
    });
    
    test('Remaining validity months calculation', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 540));
      expect(riskService.remainingValidityMonths(oldDate), equals(0));
      
      final recentDate = DateTime.now().subtract(const Duration(days: 30));
      expect(riskService.remainingValidityMonths(recentDate), greaterThan(0));
    });
  });
  
  group('User Entity Tests', () {
    test('User serialization', () {
      final user = User(
        id: 'test_id',
        phone: '13800138000',
        nickname: '测试用户',
        riskLevel: RiskLevel.balanced,
        createdAt: DateTime(2024, 1, 1),
      );
      
      final json = user.toJson();
      final restored = User.fromJson(json);
      
      expect(restored.id, equals(user.id));
      expect(restored.phone, equals(user.phone));
      expect(restored.nickname, equals(user.nickname));
      expect(restored.riskLevel, equals(user.riskLevel));
    });
    
    test('User copyWith', () {
      final user = User(
        id: 'test_id',
        phone: '13800138000',
        nickname: '测试用户',
        createdAt: DateTime.now(),
      );
      
      final updated = user.copyWith(
        nickname: '新昵称',
        riskLevel: RiskLevel.aggressive,
      );
      
      expect(updated.nickname, equals('新昵称'));
      expect(updated.riskLevel, equals(RiskLevel.aggressive));
      expect(updated.phone, equals(user.phone)); // Unchanged
    });
    
    test('RiskLevel display names', () {
      expect(RiskLevel.conservative.displayName, contains('C1'));
      expect(RiskLevel.steady.displayName, contains('C2'));
      expect(RiskLevel.balanced.displayName, contains('C3'));
      expect(RiskLevel.aggressive.displayName, contains('C4'));
      expect(RiskLevel.radical.displayName, contains('C5'));
    });
  });
  
  group('RiskAssessment Entity Tests', () {
    test('RiskAssessment static method calculateRiskLevel', () {
      expect(RiskAssessment.calculateRiskLevel(20), equals(RiskLevel.conservative));
      expect(RiskAssessment.calculateRiskLevel(35), equals(RiskLevel.steady));
      expect(RiskAssessment.calculateRiskLevel(55), equals(RiskLevel.balanced));
      expect(RiskAssessment.calculateRiskLevel(75), equals(RiskLevel.aggressive));
      expect(RiskAssessment.calculateRiskLevel(95), equals(RiskLevel.radical));
    });
  });
}
