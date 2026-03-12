import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/user.dart';
import '../domain/entities/risk_questions.dart';
import '../domain/repositories/user_repository.dart';
import '../domain/services/risk_assessment_service.dart';
import '../data/repositories/user_repository_impl.dart';
import '../data/services/auth_service.dart';
import '../data/services/user_storage_service.dart';

/// 认证服务 Provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// 用户存储服务 Provider
final userStorageServiceProvider = Provider<UserStorageService>((ref) {
  return UserStorageService();
});

/// 风险评估服务 Provider
final riskAssessmentServiceProvider = Provider<RiskAssessmentService>((ref) {
  return RiskAssessmentService();
});

/// 用户Repository Provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(
    authService: ref.watch(authServiceProvider),
    storageService: ref.watch(userStorageServiceProvider),
    riskAssessmentService: ref.watch(riskAssessmentServiceProvider),
  );
});

/// 当前用户状态
final currentUserProvider = StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});

/// 用户状态管理器
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  final UserRepository _repository;
  
  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadUser();
  }
  
  /// 加载用户数据
  Future<void> _loadUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
  
  /// 发送验证码
  /// 返回结果包含是否成功和可能的错误信息
  Future<SendCodeResult> sendVerificationCode(String phone) async {
    try {
      final success = await _repository.sendVerificationCode(phone);
      if (success) {
        return SendCodeResult.success();
      } else {
        return SendCodeResult.failure('手机号格式不正确');
      }
    } catch (e) {
      return SendCodeResult.failure('发送验证码失败：$e');
    }
  }
  
  /// 验证码登录
  /// 成功登录后自动更新用户状态
  Future<LoginResult> loginWithCode(String phone, String code) async {
    try {
      final user = await _repository.loginWithCode(phone, code);
      if (user != null) {
        state = AsyncValue.data(user);
        return LoginResult.success(user);
      } else {
        return LoginResult.failure('验证码错误或已过期');
      }
    } catch (e) {
      return LoginResult.failure('登录失败：$e');
    }
  }
  
  /// 退出登录
  Future<void> logout() async {
    await _repository.deleteUser();
    state = const AsyncValue.data(null);
  }
  
  /// 更新用户信息
  Future<void> updateUser(User user) async {
    await _repository.saveUser(user);
    state = AsyncValue.data(user);
  }
  
  /// 更新用户昵称
  Future<void> updateNickname(String nickname) async {
    final currentUser = state.value;
    if (currentUser != null) {
      final updated = currentUser.copyWith(nickname: nickname);
      await updateUser(updated);
    }
  }
  
  /// 更新用户头像
  Future<void> updateAvatar(String avatarUrl) async {
    final currentUser = state.value;
    if (currentUser != null) {
      final updated = currentUser.copyWith(avatarUrl: avatarUrl);
      await updateUser(updated);
    }
  }
  
  /// 保存风险测评结果
  Future<void> saveRiskAssessment(RiskAssessment assessment) async {
    await _repository.saveRiskAssessment(assessment);
    final currentUser = state.value;
    if (currentUser != null) {
      state = AsyncValue.data(currentUser.copyWith(
        riskLevel: assessment.riskLevel,
        riskAssessmentDate: assessment.assessedAt,
      ));
    }
  }
  
  /// 执行风险测评
  /// 根据用户答案计算风险等级并保存
  Future<RiskAssessment?> performRiskAssessment(Map<int, int> answers) async {
    final currentUser = state.value;
    if (currentUser == null) return null;
    
    // 验证答案完整性
    final missing = _validateAnswers(answers);
    if (missing.isNotEmpty) {
      return null;
    }
    
    // 计算总分
    int totalScore = 0;
    final answerList = <RiskAnswer>[];
    
    answers.forEach((questionIndex, answerIndex) {
      final question = riskQuestions[questionIndex];
      final score = question.options[answerIndex].score;
      totalScore += score;
      
      answerList.add(RiskAnswer(
        questionIndex: questionIndex,
        answerIndex: answerIndex,
        score: score,
      ));
    });
    
    // 计算风险等级
    final riskLevel = RiskAssessment.calculateRiskLevel(totalScore);
    
    // 创建测评结果
    final assessment = RiskAssessment(
      id: _generateAssessmentId(),
      userId: currentUser.id,
      answers: answerList,
      totalScore: totalScore,
      riskLevel: riskLevel,
      assessedAt: DateTime.now(),
    );
    
    // 保存测评结果
    await saveRiskAssessment(assessment);
    
    return assessment;
  }
  
  /// 验证答案完整性
  List<int> _validateAnswers(Map<int, int> answers) {
    final missing = <int>[];
    for (int i = 0; i < riskQuestions.length; i++) {
      if (!answers.containsKey(i)) {
        missing.add(i);
      }
    }
    return missing;
  }
  
  /// 生成测评ID
  String _generateAssessmentId() {
    return 'assessment_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// 检查是否需要风险测评
  bool needsRiskAssessment() {
    final user = state.value;
    if (user == null) return false;
    
    // 未测评过
    if (user.riskLevel == RiskLevel.unknown) return true;
    
    // 超过18个月需要重测
    if (user.riskAssessmentDate != null) {
      final monthsSince = DateTime.now()
          .difference(user.riskAssessmentDate!)
          .inDays ~/ 30;
      return monthsSince >= 18;
    }
    
    return true;
  }
  
  /// 获取风险测评剩余有效期（月）
  int getRemainingValidityMonths() {
    final user = state.value;
    if (user?.riskAssessmentDate == null) return 0;
    
    final monthsSince = DateTime.now()
        .difference(user!.riskAssessmentDate!)
        .inDays ~/ 30;
    final remaining = 18 - monthsSince;
    return remaining > 0 ? remaining : 0;
  }
  
  /// 刷新用户数据
  Future<void> refresh() async {
    await _loadUser();
  }
}

/// 发送验证码结果
class SendCodeResult {
  final bool success;
  final String? errorMessage;
  
  const SendCodeResult._({
    required this.success,
    this.errorMessage,
  });
  
  factory SendCodeResult.success() => const SendCodeResult._(success: true);
  
  factory SendCodeResult.failure(String message) =>
      SendCodeResult._(success: false, errorMessage: message);
}

/// 登录结果
class LoginResult {
  final bool success;
  final User? user;
  final String? errorMessage;
  
  const LoginResult._({
    required this.success,
    this.user,
    this.errorMessage,
  });
  
  factory LoginResult.success(User user) =>
      LoginResult._(success: true, user: user);
  
  factory LoginResult.failure(String message) =>
      LoginResult._(success: false, errorMessage: message);
}

/// 用户是否已登录
final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

/// 用户风险等级
final userRiskLevelProvider = Provider<RiskLevel>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user?.riskLevel ?? RiskLevel.unknown,
    orElse: () => RiskLevel.unknown,
  );
});

/// 用户昵称
final userNicknameProvider = Provider<String>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user?.nickname ?? '未登录',
    orElse: () => '加载中...',
  );
});

/// 用户手机号
final userPhoneProvider = Provider<String>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user?.phone ?? '',
    orElse: () => '',
  );
});

/// 风险测评是否过期
final riskAssessmentExpiredProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) {
      if (user?.riskAssessmentDate == null) return true;
      final monthsSince = DateTime.now()
          .difference(user!.riskAssessmentDate!)
          .inDays ~/ 30;
      return monthsSince >= 18;
    },
    orElse: () => true,
  );
});

/// 投资建议 Provider
final investmentAdviceProvider = Provider<InvestmentAdvice?>((ref) {
  final riskLevel = ref.watch(userRiskLevelProvider);
  if (riskLevel == RiskLevel.unknown) return null;
  
  final service = ref.watch(riskAssessmentServiceProvider);
  return service.getInvestmentAdvice(riskLevel);
});
