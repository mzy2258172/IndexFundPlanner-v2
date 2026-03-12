import '../domain/entities/user.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/services/risk_assessment_service.dart';
import 'services/auth_service.dart';
import 'services/user_storage_service.dart';

/// 用户仓库实现
/// 整合认证服务、存储服务和风险评估服务
class UserRepositoryImpl implements UserRepository {
  final AuthService _authService;
  final UserStorageService _storageService;
  final RiskAssessmentService _riskAssessmentService;
  
  UserRepositoryImpl({
    AuthService? authService,
    UserStorageService? storageService,
    RiskAssessmentService? riskAssessmentService,
  })  : _authService = authService ?? AuthService(),
        _storageService = storageService ?? UserStorageService(),
        _riskAssessmentService = riskAssessmentService ?? RiskAssessmentService();
  
  @override
  Future<User?> getCurrentUser() async {
    return await _storageService.getCurrentUser();
  }
  
  @override
  Future<void> saveUser(User user) async {
    await _storageService.saveCurrentUser(user);
  }
  
  @override
  Future<void> deleteUser() async {
    await _storageService.deleteCurrentUser();
  }
  
  @override
  Future<void> saveRiskAssessment(RiskAssessment assessment) async {
    await _storageService.saveRiskAssessment(assessment);
  }
  
  @override
  Future<RiskAssessment?> getLatestRiskAssessment() async {
    return await _storageService.getLatestRiskAssessment();
  }
  
  @override
  Future<bool> sendVerificationCode(String phone) async {
    // 验证手机号格式
    if (!_authService.isValidPhoneNumber(phone)) {
      return false;
    }
    
    // 发送验证码
    final result = await _authService.sendVerificationCode(phone);
    return result.success;
  }
  
  @override
  Future<User?> loginWithCode(String phone, String code) async {
    // 验证验证码
    final verifyResult = _authService.verifyCode(phone, code);
    if (!verifyResult.success) {
      return null;
    }
    
    // 创建或获取用户
    final now = DateTime.now();
    final user = User(
      id: _generateUserId(phone),
      phone: phone,
      nickname: _generateNickname(phone),
      createdAt: now,
    );
    
    // 保存用户
    await saveUser(user);
    return user;
  }
  
  @override
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }
  
  /// 生成用户ID
  String _generateUserId(String phone) {
    return 'user_${phone.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 生成默认昵称
  String _generateNickname(String phone) {
    return '用户${phone.substring(7)}';
  }
  
  /// 执行风险评估
  RiskAssessmentResult performRiskAssessment(
    String userId,
    Map<int, int> answers,
  ) {
    return _riskAssessmentService.assess(userId, answers);
  }
  
  /// 获取投资建议
  InvestmentAdvice getInvestmentAdvice(RiskLevel riskLevel) {
    return _riskAssessmentService.getInvestmentAdvice(riskLevel);
  }
  
  /// 检查是否需要重新评估风险
  bool needsRiskReassessment(DateTime? lastAssessmentDate) {
    return _riskAssessmentService.needsReassessment(lastAssessmentDate);
  }
  
  /// 获取风险测评剩余有效期
  int getRemainingValidityMonths(DateTime? lastAssessmentDate) {
    return _riskAssessmentService.remainingValidityMonths(lastAssessmentDate);
  }
  
  /// 获取风险测评历史
  Future<List<RiskAssessment>> getRiskAssessmentHistory() async {
    return await _storageService.getRiskAssessmentHistory();
  }
  
  /// 导出用户数据
  Future<Map<String, dynamic>> exportUserData() async {
    return await _storageService.exportUserData();
  }
}
