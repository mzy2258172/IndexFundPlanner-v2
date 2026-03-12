/// 认证服务 - 处理用户注册/登录逻辑
class AuthService {
  // 验证码有效期（分钟）
  static const int codeExpiryMinutes = 5;
  
  // 存储验证码（模拟，实际应使用Redis或缓存服务）
  final Map<String, _VerificationCode> _codeStorage = {};
  
  /// 验证手机号格式
  /// 中国大陆手机号规则：
  /// - 11位数字
  /// - 以1开头
  /// - 第二位为3-9
  bool isValidPhoneNumber(String phone) {
    if (phone.length != 11) return false;
    
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phone);
  }
  
  /// 生成6位验证码
  String generateVerificationCode() {
    // 实际应用中应该使用安全的随机数生成器
    final now = DateTime.now().millisecondsSinceEpoch;
    final code = (now % 1000000).toString().padLeft(6, '0');
    return code;
  }
  
  /// 发送验证码
  /// 返回生成的验证码（用于测试环境展示）
  Future<SendCodeResult> sendVerificationCode(String phone) async {
    // 验证手机号格式
    if (!isValidPhoneNumber(phone)) {
      return SendCodeResult(
        success: false,
        errorMessage: '手机号格式不正确',
      );
    }
    
    // 模拟发送延迟
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 生成验证码
    final code = generateVerificationCode();
    final expiryTime = DateTime.now().add(const Duration(minutes: codeExpiryMinutes));
    
    // 存储验证码
    _codeStorage[phone] = _VerificationCode(
      code: code,
      expiryTime: expiryTime,
      createdAt: DateTime.now(),
    );
    
    // 实际应用中这里应该调用短信服务API
    // 例如：阿里云短信、腾讯云短信等
    // await _smsService.send(phone, code);
    
    return SendCodeResult(
      success: true,
      code: code, // 测试环境返回验证码
    );
  }
  
  /// 验证验证码
  VerifyCodeResult verifyCode(String phone, String code) {
    // 检查手机号格式
    if (!isValidPhoneNumber(phone)) {
      return VerifyCodeResult(
        success: false,
        errorMessage: '手机号格式不正确',
      );
    }
    
    // 检查验证码格式
    if (code.length != 6) {
      return VerifyCodeResult(
        success: false,
        errorMessage: '验证码应为6位数字',
      );
    }
    
    // 获取存储的验证码
    final storedCode = _codeStorage[phone];
    
    // 没有发送过验证码
    if (storedCode == null) {
      return VerifyCodeResult(
        success: false,
        errorMessage: '请先获取验证码',
      );
    }
    
    // 验证码已过期
    if (DateTime.now().isAfter(storedCode.expiryTime)) {
      _codeStorage.remove(phone);
      return VerifyCodeResult(
        success: false,
        errorMessage: '验证码已过期，请重新获取',
      );
    }
    
    // 验证码不匹配
    if (storedCode.code != code) {
      // 记录失败次数（可用于防暴力破解）
      storedCode.failedAttempts++;
      
      if (storedCode.failedAttempts >= 5) {
        _codeStorage.remove(phone);
        return VerifyCodeResult(
          success: false,
          errorMessage: '验证码错误次数过多，请重新获取',
        );
      }
      
      return VerifyCodeResult(
        success: false,
        errorMessage: '验证码错误',
      );
    }
    
    // 验证成功，清除验证码
    _codeStorage.remove(phone);
    
    return VerifyCodeResult(
      success: true,
    );
  }
  
  /// 清除过期的验证码（可定期调用）
  void clearExpiredCodes() {
    final now = DateTime.now();
    _codeStorage.removeWhere((_, code) => now.isAfter(code.expiryTime));
  }
  
  /// 测试用途：获取指定手机号的验证码
  String? getTestCode(String phone) {
    return _codeStorage[phone]?.code;
  }
}

/// 验证码存储结构
class _VerificationCode {
  final String code;
  final DateTime expiryTime;
  final DateTime createdAt;
  int failedAttempts;
  
  _VerificationCode({
    required this.code,
    required this.expiryTime,
    required this.createdAt,
    this.failedAttempts = 0,
  });
}

/// 发送验证码结果
class SendCodeResult {
  final bool success;
  final String? errorMessage;
  final String? code; // 仅用于测试环境
  
  const SendCodeResult({
    required this.success,
    this.errorMessage,
    this.code,
  });
}

/// 验证验证码结果
class VerifyCodeResult {
  final bool success;
  final String? errorMessage;
  
  const VerifyCodeResult({
    required this.success,
    this.errorMessage,
  });
}
