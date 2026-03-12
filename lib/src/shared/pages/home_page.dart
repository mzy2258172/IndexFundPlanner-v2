import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../user/presentation/providers/user_provider.dart';
import '../../plan/presentation/providers/plan_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final plansAsync = ref.watch(userPlansProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('指数基金规划师'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: 消息通知
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildContent(context, ref, user, plansAsync),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/create-plan'),
        icon: const Icon(Icons.add),
        label: const Text('创建计划'),
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context, 
    WidgetRef ref, 
    dynamic user,
    AsyncValue<List<dynamic>> plansAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 用户信息卡片
          _buildUserCard(context, ref, user),
          const SizedBox(height: 16),
          
          // 资产概览卡片
          _buildAssetCard(context, ref),
          const SizedBox(height: 24),
          
          // 我的投资计划
          _buildPlansSection(context, plansAsync),
          const SizedBox(height: 24),
          
          // 快捷入口
          _buildQuickActions(context),
          const SizedBox(height: 24),
          
          // 推荐基金
          _buildRecommendFunds(context),
          const SizedBox(height: 100), // FAB 空间
        ],
      ),
    );
  }
  
  Widget _buildUserCard(BuildContext context, WidgetRef ref, dynamic user) {
    if (user == null) return const SizedBox.shrink();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                user.nickname.isNotEmpty ? user.nickname[0] : 'U',
                style: TextStyle(
                  fontSize: 24,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.riskLevel.shortName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => context.push('/settings'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssetCard(BuildContext context, WidgetRef ref) {
    // 模拟资产数据
    const totalAsset = 128456.32;
    const totalProfit = 18456.32;
    const profitRate = 16.78;
    
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '总资产',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                Icon(
                  Icons.visibility_outlined,
                  size: 20,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${totalAsset.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '累计收益',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '+¥${totalProfit.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '收益率',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '+${profitRate.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今日收益',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '+¥234.56',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPlansSection(BuildContext context, AsyncValue<List<dynamic>> plansAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '我的投资计划',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => context.push('/portfolio'),
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无投资计划',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () => context.push('/create-plan'),
                        child: const Text('创建第一个计划'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: plans.length > 3 ? 3 : plans.length,
                itemBuilder: (context, index) {
                  final plan = plans[index];
                  return _buildPlanCard(context, plan);
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, st) => Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('加载失败: $e'),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlanCard(BuildContext context, dynamic plan) {
    final progress = (plan.currentAmount / plan.targetAmount).clamp(0.0, 1.0);
    
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => context.push('/plan/${plan.id}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      plan.goalType.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        plan.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '目标: ¥${(plan.targetAmount / 10000).toStringAsFixed(1)}万',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '进度 ${(progress * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '剩余 ${plan.remainingMonths} 月',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快捷入口',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildActionButton(
              context,
              Icons.search,
              '基金查询',
              () => context.push('/funds'),
            ),
            _buildActionButton(
              context,
              Icons.pie_chart_outline,
              '持仓分析',
              () => context.push('/analytics'),
            ),
            _buildActionButton(
              context,
              Icons.auto_graph,
              '定投策略',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('定投策略功能开发中')),
                );
              },
            ),
            _buildActionButton(
              context,
              Icons.school_outlined,
              '投资学堂',
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('投资学堂功能开发中')),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRecommendFunds(BuildContext context) {
    final funds = [
      {'code': '510300', 'name': '沪深300ETF', 'rate': '+12.56%'},
      {'code': '510500', 'name': '中证500ETF', 'rate': '+15.23%'},
      {'code': '159915', 'name': '创业板ETF', 'rate': '+18.45%'},
    ];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '推荐基金',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => context.push('/funds'),
              child: const Text('更多'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        ...funds.map((fund) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  fund['code'].toString().substring(0, 3),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            title: Text(fund['name'] as String),
            subtitle: Text(fund['code'] as String),
            trailing: Text(
              fund['rate'] as String,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => context.push('/fund/${fund['code']}'),
          ),
        )),
      ],
    );
  }
}
