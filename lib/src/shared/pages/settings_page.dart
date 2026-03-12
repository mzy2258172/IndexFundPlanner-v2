import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/user/presentation/providers/user_provider.dart';
import '../../features/user/domain/entities/user.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _darkMode = false;
  bool _notifications = true;
  
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 用户信息
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              
              return Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          user.nickname.isNotEmpty ? user.nickname[0] : 'U',
                          style: TextStyle(
                            fontSize: 28,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.nickname,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.phone.replaceRange(3, 7, '****'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.riskLevel.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          // TODO: 编辑资料
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          
          // 账户设置
          const _SectionHeader(title: '账户'),
          ListTile(
            leading: const Icon(Icons.assessment_outlined),
            title: const Text('重新风险测评'),
            subtitle: const Text('更新您的风险偏好'),
            onTap: () => context.push('/risk-assessment'),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: const Text('银行卡管理'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('银行卡管理功能开发中')),
              );
            },
          ),
          
          // 外观设置
          const _SectionHeader(title: '外观'),
          SwitchListTile(
            title: const Text('深色模式'),
            subtitle: const Text('使用深色主题'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
            },
          ),
          
          // 通知设置
          const _SectionHeader(title: '通知'),
          SwitchListTile(
            title: const Text('净值提醒'),
            subtitle: const Text('基金净值变动时通知'),
            value: _notifications,
            onChanged: (value) {
              setState(() => _notifications = value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('定投提醒'),
            subtitle: const Text('扣款日前一天提醒'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up_outlined),
            title: const Text('收益周报'),
            subtitle: const Text('每周一发送收益报告'),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
            ),
          ),
          
          // 数据管理
          const _SectionHeader(title: '数据'),
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('备份数据'),
            subtitle: const Text('将数据备份到云端'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('备份功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('恢复数据'),
            subtitle: const Text('从云端恢复数据'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('恢复功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('清除数据', style: TextStyle(color: Colors.red)),
            subtitle: const Text('清除所有本地数据'),
            onTap: () => _showClearDataDialog(context),
          ),
          
          // 关于
          const _SectionHeader(title: '关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('版本'),
            subtitle: Text('1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('帮助中心'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('帮助中心开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: const Text('意见反馈'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('意见反馈功能开发中')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('开源许可'),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
          
          // 退出登录
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('退出登录'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除数据'),
        content: const Text('此操作将清除所有本地数据，包括投资组合和设置。此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(currentUserProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('确认', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(currentUserProvider.notifier).logout();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  
  const _SectionHeader({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
