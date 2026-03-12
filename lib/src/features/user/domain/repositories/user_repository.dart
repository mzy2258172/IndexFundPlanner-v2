import '../entities/user.dart';

abstract class UserRepository {
  /// 获取当前用户
  Future<User?> getCurrentUser();
  
  /// 保存用户
  Future<void> saveUser(User user);
  
  /// 删除用户（退出登录）
  Future<void> deleteUser();
  
  /// 保存风险测评结果
  Future<void> saveRiskAssessment(RiskAssessment assessment);
  
  /// 获取最近的风险测评
  Future<RiskAssessment?> getLatestRiskAssessment();
  
  /// 发送验证码
  Future<bool> sendVerificationCode(String phone);
  
  /// 验证码登录
  Future<User?> loginWithCode(String phone, String code);
  
  /// 检查用户是否已登录
  Future<bool> isLoggedIn();
}
