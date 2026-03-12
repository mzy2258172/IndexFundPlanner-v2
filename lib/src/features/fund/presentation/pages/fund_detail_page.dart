import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../domain/entities/fund.dart';
import '../providers/fund_provider.dart';

class FundDetailPage extends ConsumerStatefulWidget {
  final String fundCode;
  
  const FundDetailPage({
    super.key,
    required this.fundCode,
  });
  
  @override
  ConsumerState<FundDetailPage> createState() => _FundDetailPageState();
}

class _FundDetailPageState extends ConsumerState<FundDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fundDetailNotifierProvider(widget.fundCode).notifier)
        .loadFundDetail(widget.fundCode);
      ref.read(netValueHistoryNotifierProvider(widget.fundCode).notifier)
        .loadHistory(widget.fundCode, days: 90);
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final detailState = ref.watch(fundDetailNotifierProvider(widget.fundCode));
    final historyState = ref.watch(netValueHistoryNotifierProvider(widget.fundCode));
    
    if (detailState.isLoading && detailState.detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (detailState.error != null && detailState.detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _buildErrorWidget(detailState.error!, () {
          ref.read(fundDetailNotifierProvider(widget.fundCode).notifier)
            .loadFundDetail(widget.fundCode, forceRefresh: true);
        }),
      );
    }
    
    final detail = detailState.detail;
    if (detail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('未找到基金信息')),
      );
    }
    
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(fundDetailNotifierProvider(widget.fundCode).notifier)
            .refresh(widget.fundCode);
          await ref.read(netValueHistoryNotifierProvider(widget.fundCode).notifier)
            .loadHistory(widget.fundCode, days: 90, forceRefresh: true);
        },
        child: _buildContent(context, detail, historyState.history),
      ),
      bottomNavigationBar: _buildBottomBar(context, detail.fund),
    );
  }
  
  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('加载失败: $error'),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context, FundDetail detail, List<FundNetValue> history) {
    final fund = detail.fund;
    
    return CustomScrollView(
      slivers: [
        // 顶部区域
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildHeader(context, fund),
          ),
        ),
        
        // 内容区域
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 收益率卡片
                _buildReturnCard(context, fund),
                const SizedBox(height: 16),
                
                // 净值走势
                _buildNetValueChart(context, history),
                const SizedBox(height: 16),
                
                // 基金信息
                _buildFundInfo(context, fund),
                const SizedBox(height: 16),
                
                // 费率信息
                _buildFeeInfo(context, fund),
                const SizedBox(height: 100), // 底部按钮空间
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context, Fund fund) {
    final isUp = fund.dayChangeRate >= 0;
    final color = isUp ? Colors.red : Colors.green;
    
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
            Text(
              fund.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${fund.code} · ${fund.type}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  fund.currentPrice.toStringAsFixed(4),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${isUp ? '+' : ''}${fund.dayChange.toStringAsFixed(4)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '${isUp ? '+' : ''}${fund.dayChangeRate.toStringAsFixed(2)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                _buildTag(context, fund.riskLevelName),
                const SizedBox(width: 8),
                if (fund.fundCompany != null)
                  _buildTag(context, fund.fundCompany!),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
  
  Widget _buildReturnCard(BuildContext context, Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '收益率',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildReturnItem(context, '近1年', fund.return1y),
                _buildReturnItem(context, '近3年', fund.return3y),
                _buildReturnItem(context, '近5年', fund.return5y),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildReturnItem(BuildContext context, String label, double? value) {
    final displayValue = value ?? 0;
    final color = displayValue >= 0 ? Colors.red : Colors.green;
    
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${displayValue >= 0 ? '+' : ''}${displayValue.toStringAsFixed(2)}%',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: value != null ? color : null,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetValueChart(BuildContext context, List<FundNetValue> history) {
    if (history.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '净值走势',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text('暂无净值数据'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    }
    
    // 按日期排序（从旧到新）
    final sortedHistory = List<FundNetValue>.from(history)
      ..sort((a, b) => a.date.compareTo(b.date));
    
    // 取最近30条数据用于显示
    final displayHistory = sortedHistory.length > 30 
      ? sortedHistory.sublist(sortedHistory.length - 30) 
      : sortedHistory;
    
    final spots = displayHistory.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.netValue);
    }).toList();
    
    // 计算Y轴范围
    final values = displayHistory.map((e) => e.netValue).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxValue - minValue) * 0.1;
    
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
                  '净值走势',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: () => _showHistorySheet(context, history),
                  child: const Text('查看更多'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: minValue - padding,
                  maxY: maxValue + padding,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxValue - minValue) / 4,
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toStringAsFixed(2),
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
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 2,
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
          ],
        ),
      ),
    );
  }
  
  void _showHistorySheet(BuildContext context, List<FundNetValue> history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '净值历史',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return ListTile(
                      title: Text('净值: ${item.netValue.toStringAsFixed(4)}'),
                      subtitle: Text(
                        '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: item.dayChangeRate != null
                        ? Text(
                            '${item.dayChangeRate! >= 0 ? '+' : ''}${item.dayChangeRate!.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: item.dayChangeRate! >= 0 ? Colors.red : Colors.green,
                            ),
                          )
                        : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildFundInfo(BuildContext context, Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基金信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, '基金公司', fund.fundCompany ?? '-'),
            _buildInfoRow(context, '基金规模', 
              fund.scale != null ? '${fund.scale!.toStringAsFixed(2)}亿' : '-'),
            _buildInfoRow(context, '成立日期', 
              fund.establishDate != null 
                ? '${fund.establishDate!.year}-${fund.establishDate!.month.toString().padLeft(2, '0')}-${fund.establishDate!.day.toString().padLeft(2, '0')}'
                : '-'),
            _buildInfoRow(context, '跟踪指数', fund.trackingIndex ?? '-'),
            _buildInfoRow(context, '风险等级', fund.riskLevelName),
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
  
  Widget _buildFeeInfo(BuildContext context, Fund fund) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '费率信息',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, '管理费', 
              fund.managementFee != null 
                ? '${(fund.managementFee! * 100).toStringAsFixed(2)}%' 
                : '-'),
            _buildInfoRow(context, '托管费', 
              fund.custodyFee != null 
                ? '${(fund.custodyFee! * 100).toStringAsFixed(2)}%' 
                : '-'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '申购费率以销售平台为准，持有少于7天可能收取惩罚性赎回费',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
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
  
  Widget _buildBottomBar(BuildContext context, Fund fund) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: 添加到组合
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已添加到自选')),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('加自选'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: () {
                  // TODO: 创建投资计划
                  context.push('/create-plan?fundCode=${fund.code}');
                },
                child: const Text('创建定投计划'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
