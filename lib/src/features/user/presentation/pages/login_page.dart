import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/user_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  int _countdown = 0;
  bool _loading = false;
  String? _error;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
  
  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 11) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final success = await ref.read(currentUserProvider.notifier).sendVerificationCode(phone);
      if (success && mounted) {
        setState(() {
          _codeSent = true;
          _countdown = 60;
        });
        _startCountdown();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _countdown--);
      return _countdown > 0;
    });
  }
  
  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    
    if (phone.length != 11) {
      setState(() => _error = '请输入正确的手机号');
      return;
    }
    
    if (code.length != 6) {
      setState(() => _error = '请输入6位验证码');
      return;
    }
    
    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      final success = await ref.read(currentUserProvider.notifier).loginWithCode(phone, code);
      if (success && mounted) {
        // 登录成功，检查是否需要风险测评
        final needsAssessment = ref.read(currentUserProvider.notifier).needsRiskAssessment();
        if (needsAssessment) {
          context.go('/risk-assessment');
        } else {
          context.go('/home');
        }
      } else if (mounted) {
        setState(() => _error = '验证码错误');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo
              Icon(
                Icons.account_balance_wallet_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                '指数基金规划师',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '智能定投，稳健增值',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // 手机号输入
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入手机号',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '',
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 验证码输入
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入验证码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _countdown > 0 || _loading ? null : _sendCode,
                      child: Text(
                        _countdown > 0 ? '${_countdown}s' : (_codeSent ? '重发' : '获取验证码'),
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              
              const SizedBox(height: 24),
              
              // 登录按钮
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登录 / 注册', style: TextStyle(fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 提示
              Text(
                '提示：测试环境验证码为 123456 或 000000',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // 协议
              Text.rich(
                TextSpan(
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  children: const [
                    TextSpan(text: '登录即表示同意'),
                    TextSpan(
                      text: '《用户协议》',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                    TextSpan(text: '和'),
                    TextSpan(
                      text: '《隐私政策》',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
