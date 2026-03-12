import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/portfolio_provider.dart';

class PortfolioPage extends ConsumerWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(portfolioListProvider);
    final stats = ref.watch(portfolioStatsProvider);
    final distribution = ref.watch(portfolioDistributionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('投资组合'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(portfolioListProvider.notifier).loadPortfolios();
            },
          ),
        ],
      ),
      body: state.when(
        initial: () => const Center(child: Text('初始化中...')),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (portfolios) => _buildContent(
          context,
          ref,
          portfolios,
          stats,
          distribution,
        ),
        error: (message) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('加载失败: $message'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.read(portfolioListProvider.notifier).loadPortfolios();
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePortfolioDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新建组合'),
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List portfolios,
    Map<String, dynamic> stats,
    Map<String, double> distribution,
  ) {
    if (portfolios.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总资产卡片
        _buildTotalAssetCard(context, stats),
        const SizedBox(height: 16),
        
        // 收益概览
        _buildProfitOverviewCard(context, stats),
        const SizedBox(height: 16),
        
        // 持仓分布
        if (distribution.isNotEmpty) ...[
          _buildDistributionCard(context, distribution, stats['totalValue'] as double),
          const SizedBox(height: 16),
        ],
        
        // 组合列表
        Text(
          '我的组合',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...portfolios.map((portfolio) => _buildPortfolioCard(context, ref, portfolio)),
        
        const SizedBox(height: 80), // FAB 空间
      ],
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 24),
          Text(
            '暂无投资组合',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '创建您的第一个投资组合\n开始记录您的投资旅程',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/add-holding'),
            icon: const Icon(Icons.add),
            label: const Text('添加第一笔持仓'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTotalAssetCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final totalValue = stats['totalValue'] as double;
    final totalInvestment = stats['totalInvestment'] as double;
    
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
              '¥${totalValue.toStringAsFixed(2)}',
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
                        '总投入',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '¥${totalInvestment.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                        '持仓数量',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${stats['itemCount']} 只',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
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
  
  Widget _buildProfitOverviewCard(
    BuildContext context,
    Map<String, dynamic> stats,
  ) {
    final totalProfit = stats['totalProfit'] as double;
    final totalReturnRate = stats['totalReturnRate'] as double;
    final todayProfit = stats['todayProfit'] as double;
    final isProfit = totalProfit >= 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildProfitItem(
                    context,
                    '累计收益',
                    '${isProfit ? '+' : ''}¥${totalProfit.toStringAsFixed(2)}',
                    isProfit ? Colors.green : Colors.red,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildProfitItem(
                    context,
                    '收益率',
                    '${isProfit ? '+' : ''}${(totalReturnRate * 100).toStringAsFixed(2)}%',
                    isProfit ? Colors.green : Colors.red,
                  ),
                ),
                Container(
                  width: 1,
                  height: 50,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _buildProfitItem(
                    context,
                    '今日收益',
                    '+¥${todayProfit.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfitItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDistributionCard(
    BuildContext context,
    Map<String, double> distribution,
    double total,
  ) {
    if (distribution.isEmpty || total <= 0) return const SizedBox.shrink();
    
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '持仓分布',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => context.push('/analytics'),
                  child: const Text('详细分析'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  // 饼图
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: distribution.entries
                            .map((e) {
                              final index = distribution.keys.toList().indexOf(e.key);
                              return PieChartSectionData(
                                color: colors[index % colors.length],
                                value: e.value,
                                title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                                radius: 50,
                                titleStyle: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                  ),
                  // 图例
                  SizedBox(
                    width: 100,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: distribution.entries.take(4).map((e) {
                        final index = distribution.keys.toList().indexOf(e.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
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
  
  Widget _buildPortfolioCard(
    BuildContext context,
    WidgetRef ref,
    dynamic portfolio,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/portfolio/${portfolio.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${portfolio.items.length} 只基金',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '¥${portfolio.totalValue.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${(portfolio.totalReturnRate * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: portfolio.totalReturnRate >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (portfolio.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  portfolio.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  void _showCreatePortfolioDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: '我的投资组合');
    final descController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建投资组合'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '组合名称',
                hintText: '例如: 养老金组合',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: '组合描述（可选）',
                hintText: '例如: 长期定投养老规划',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final portfolio = Portfolio(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text.trim(),
                description: descController.text.trim(),
                items: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await ref.read(portfolioListProvider.notifier).addPortfolio(portfolio);
              
              if (context.mounted) {
                Navigator.pop(context);
                context.push('/portfolio/${portfolio.id}');
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
