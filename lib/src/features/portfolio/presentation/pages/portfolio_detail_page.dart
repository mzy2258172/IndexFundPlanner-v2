import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/portfolio.dart';
import '../providers/portfolio_provider.dart';

/// 持仓详情页面
class PortfolioDetailPage extends ConsumerWidget {
  final String portfolioId;
  
  const PortfolioDetailPage({
    super.key,
    required this.portfolioId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioDetailProvider(portfolioId));
    final distribution = ref.watch(portfolioDistributionProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('持仓详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: 编辑组合
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add') {
                context.push('/portfolio/$portfolioId/add-holding');
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('添加持仓'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('删除组合', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ],
      ),
      body: portfolioAsync.when(
        data: (portfolio) {
          if (portfolio == null) {
            return const Center(child: Text('投资组合不存在'));
          }
          return _buildContent(context, ref, portfolio, distribution);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('加载失败: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-holding?portfolioId=$portfolioId'),
        icon: const Icon(Icons.add),
        label: const Text('添加持仓'),
      ),
    );
  }
  
  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Portfolio portfolio,
    Map<String, double> distribution,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 总览卡片
        _buildOverviewCard(context, portfolio),
        const SizedBox(height: 16),
        
        // 收益概览
        _buildProfitCard(context, portfolio),
        const SizedBox(height: 16),
        
        // 持仓分布图表
        if (portfolio.items.isNotEmpty) ...[
          _buildDistributionChart(context, portfolio),
          const SizedBox(height: 16),
        ],
        
        // 持仓列表
        _buildHoldingsList(context, ref, portfolio),
        const SizedBox(height: 80), // FAB 空间
      ],
    );
  }
  
  Widget _buildOverviewCard(BuildContext context, Portfolio portfolio) {
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
                  portfolio.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${portfolio.items.length} 只基金',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            if (portfolio.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                portfolio.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    '总投入',
                    '¥${portfolio.totalInvestment.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    '总市值',
                    '¥${portfolio.totalValue.toStringAsFixed(2)}',
                    Icons.paid,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfitCard(BuildContext context, Portfolio portfolio) {
    final profit = portfolio.totalValue - portfolio.totalInvestment;
    final returnRate = portfolio.totalReturnRate;
    final isProfit = profit >= 0;
    
    return Card(
      color: isProfit
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfitItem(
                  context,
                  '累计收益',
                  '${isProfit ? '+' : ''}¥${profit.toStringAsFixed(2)}',
                  isProfit ? Colors.green : Colors.red,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                _buildProfitItem(
                  context,
                  '收益率',
                  '${isProfit ? '+' : ''}${(returnRate * 100).toStringAsFixed(2)}%',
                  isProfit ? Colors.green : Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 进度条显示盈亏比例
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: returnRate.abs() > 1 ? 1.0 : returnRate.abs(),
                minHeight: 8,
                backgroundColor: isProfit 
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(
                  isProfit ? Colors.green : Colors.red,
                ),
              ),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDistributionChart(BuildContext context, Portfolio portfolio) {
    // 计算各基金占比
    final Map<String, double> fundDistribution = {};
    for (final item in portfolio.items) {
      fundDistribution[item.fundName] = item.currentValue;
    }
    
    final total = portfolio.totalValue;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '持仓分布',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // 饼图
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: fundDistribution.entries
                            .map((e) {
                              final index = fundDistribution.keys.toList().indexOf(e.key);
                              return PieChartSectionData(
                                color: colors[index % colors.length],
                                value: e.value,
                                title: '${(e.value / total * 100).toStringAsFixed(1)}%',
                                radius: 60,
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
                    width: 120,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: fundDistribution.entries.map((e) {
                        final index = fundDistribution.keys.toList().indexOf(e.key);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[index % colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.key.length > 6 ? '${e.key.substring(0, 6)}...' : e.key,
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
  
  Widget _buildHoldingsList(
    BuildContext context,
    WidgetRef ref,
    Portfolio portfolio,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '持仓明细',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        
        if (portfolio.items.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '暂无持仓记录',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.tonal(
                    onPressed: () => context.push('/add-holding?portfolioId=${portfolio.id}'),
                    child: const Text('添加第一笔持仓'),
                  ),
                ],
              ),
            ),
          )
        else
          ...portfolio.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildHoldingItem(context, ref, portfolio.id, index, item);
          }),
      ],
    );
  }
  
  Widget _buildHoldingItem(
    BuildContext context,
    WidgetRef ref,
    String portfolioId,
    int index,
    PortfolioItem item,
  ) {
    final profit = item.profit;
    final returnRate = item.returnRate;
    final isProfit = profit >= 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // TODO: 跳转到基金详情
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.fundCode.substring(0, 3),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.fundName,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          item.fundCode,
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
                        '${isProfit ? '+' : ''}¥${profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isProfit ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${isProfit ? '+' : ''}${(returnRate * 100).toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isProfit ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildItemInfo(
                      context,
                      '投入金额',
                      '¥${item.investmentAmount.toStringAsFixed(2)}',
                    ),
                  ),
                  Expanded(
                    child: _buildItemInfo(
                      context,
                      '持有份额',
                      item.shares.toStringAsFixed(2),
                    ),
                  ),
                  Expanded(
                    child: _buildItemInfo(
                      context,
                      '当前净值',
                      '¥${item.currentPrice.toStringAsFixed(4)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '买入日期: ${item.purchaseDate.year}-${item.purchaseDate.month.toString().padLeft(2, '0')}-${item.purchaseDate.day.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          _showUpdatePriceDialog(context, ref, portfolioId, index, item);
                        },
                        child: const Text('更新净值'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () {
                          _showDeleteItemDialog(context, ref, portfolioId, index);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildItemInfo(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
  
  void _showUpdatePriceDialog(
    BuildContext context,
    WidgetRef ref,
    String portfolioId,
    int index,
    PortfolioItem item,
  ) {
    final controller = TextEditingController(text: item.currentPrice.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('更新净值'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: '当前净值',
            suffixText: '元',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null && newPrice > 0) {
                ref.read(portfolioListProvider.notifier)
                    .updateItemPrice(portfolioId, index, newPrice);
                Navigator.pop(context);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteItemDialog(
    BuildContext context,
    WidgetRef ref,
    String portfolioId,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这笔持仓吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(portfolioListProvider.notifier)
                  .removePortfolioItem(portfolioId, index);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个投资组合吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(portfolioListProvider.notifier)
                  .deletePortfolio(portfolioId);
              Navigator.pop(context);
              context.pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
