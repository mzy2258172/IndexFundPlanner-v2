import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/plan.dart';
import '../providers/plan_provider.dart';

class PlanDetailPage extends ConsumerWidget {
  final String planId;
  
  const PlanDetailPage({
    super.key,
    required this.planId,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planProvider(planId));
    
    return Scaffold(
      body: planAsync.when(
        data: (plan) {
          if (plan == null) {
            return _buildNotFound(context);
          }
          return _buildContent(context, ref, plan);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('加载失败: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 16),
          const Text('计划不存在'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, WidgetRef ref, InvestmentPlan plan) {
    return CustomScrollView(
      slivers: [
        // 顶部卡片
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(context, plan),
          ),
        ),
        
        // 内容区域
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 进度卡片
                _buildProgressCard(context, plan),
                const SizedBox(height: 16),
                
                // 收益预测
                _buildPredictionCard(context, plan),
                const SizedBox(height: 16),
                
                // 组合配置
                if (plan.portfolio != null) ...[
                  _buildPortfolioCard(context, plan.portfolio!),
                  const SizedBox(height: 16),
                ],
                
                // 定投计划
                if (plan.sipPlan != null) ...[
                  _buildSipCard(context, plan.sipPlan!),
                  const SizedBox(height: 16),
                ],
                
                // 计划信息
                _buildInfoCard(context, plan),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context, InvestmentPlan plan) {
    final progress = plan.progress;
    final progressPercent = (progress * 100).clamp(0, 100);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  plan.goalType.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        plan.goalType.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(plan.status),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            
            // 进度环
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${progressPercent.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '已完成',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前金额',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '¥${_formatAmount(plan.currentAmount)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '目标金额',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '¥${_formatAmount(plan.targetAmount)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(PlanStatus status) {
    switch (status) {
      case PlanStatus.active:
        return '进行中';
      case PlanStatus.completed:
        return '已完成';
      case PlanStatus.paused:
        return '已暂停';
      case PlanStatus.terminated:
        return '已终止';
    }
  }
  
  Widget _buildProgressCard(BuildContext context, InvestmentPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '计划进度',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '剩余 ${plan.remainingMonths} 个月',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 进度条
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: plan.progress.clamp(0.0, 1.0),
                minHeight: 12,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildProgressItem(
                  context,
                  '投入本金',
                  '¥${_formatAmount(plan.initialCapital)}',
                ),
                _buildProgressItem(
                  context,
                  '月投入',
                  '¥${_formatAmount(plan.monthlyInvestment)}',
                ),
                _buildProgressItem(
                  context,
                  '开始日期',
                  '${plan.startDate.year}-${plan.startDate.month.toString().padLeft(2, '0')}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
  
  Widget _buildPredictionCard(BuildContext context, InvestmentPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收益预测',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // 简单的预测图表
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '¥${(value / 10000).toStringAsFixed(0)}万',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // 目标线
                    LineChartBarData(
                      spots: [
                        FlSpot(0, plan.targetAmount),
                        FlSpot(12, plan.targetAmount),
                      ],
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                    // 预测曲线
                    LineChartBarData(
                      spots: List.generate(12, (i) {
                        final progress = i / 11;
                        return FlSpot(
                          i.toDouble(),
                          plan.currentAmount + 
                            (plan.targetAmount - plan.currentAmount) * progress * 0.8,
                        );
                      }),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPredictionItem(
                  context,
                  '保守预测',
                  '¥${_formatAmount(plan.targetAmount * 0.85)}',
                  Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                _buildPredictionItem(
                  context,
                  '预期目标',
                  '¥${_formatAmount(plan.targetAmount)}',
                  Theme.of(context).colorScheme.primary,
                ),
                _buildPredictionItem(
                  context,
                  '乐观预测',
                  '¥${_formatAmount(plan.targetAmount * 1.15)}',
                  Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPredictionItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPortfolioCard(BuildContext context, Portfolio portfolio) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '投资组合',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    portfolio.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 配置列表
            ...portfolio.allocations.map((allocation) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(allocation.fundName),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: allocation.ratio / 100,
                            minHeight: 6,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${allocation.ratio.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 8),
            
            // 预期收益
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '预期年化收益',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${portfolio.expectedReturnMin?.toStringAsFixed(1) ?? 0}% - ${portfolio.expectedReturnMax?.toStringAsFixed(1) ?? 0}%',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSipCard(BuildContext context, SipPlan sip) {
    final frequencyText = sip.frequency == 'monthly' 
      ? '每月' 
      : sip.frequency == 'weekly' 
        ? '每周' 
        : '每两周';
    
    final strategyText = sip.strategy == 'normal'
      ? '普通定投'
      : sip.strategy == 'ma'
        ? '均线策略'
        : '价值平均';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '定投计划',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSipItem(
                    context,
                    Icons.calendar_today,
                    '定投频率',
                    '$frequencyText ${sip.investmentDay}日',
                  ),
                ),
                Expanded(
                  child: _buildSipItem(
                    context,
                    Icons.payments_outlined,
                    '定投金额',
                    '¥${_formatAmount(sip.amount)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildSipItem(
                    context,
                    Icons.trending_up,
                    '定投策略',
                    strategyText,
                  ),
                ),
                Expanded(
                  child: _buildSipItem(
                    context,
                    Icons.savings_outlined,
                    '累计投入',
                    '¥${_formatAmount(sip.totalInvested)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSipItem(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(BuildContext context, InvestmentPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '计划信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(context, '创建时间', _formatDate(plan.createdAt)),
            _buildInfoRow(context, '更新时间', _formatDate(plan.updatedAt)),
            _buildInfoRow(context, '目标日期', _formatDate(plan.targetDate)),
            
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: 暂停计划
                    },
                    icon: const Icon(Icons.pause),
                    label: const Text('暂停定投'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      // TODO: 手动投入
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('手动投入'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(2);
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
