import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';

class AnalyticsPage extends ConsumerWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(analyticsProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('投资分析'),
      ),
      body: state.when(
        initial: () => _buildInitialView(context, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        loaded: (report) => _buildReportView(context, report),
        error: (message) => Center(child: Text('错误: $message')),
      ),
    );
  }
  
  Widget _buildInitialView(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text('选择投资组合查看分析报告'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: 显示组合选择器
              ref.read(analyticsProvider.notifier).loadAnalytics('demo');
            },
            icon: const Icon(Icons.add_chart),
            label: const Text('开始分析'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReportView(BuildContext context, dynamic report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(report),
          const SizedBox(height: 16),
          _buildMetricsCard(report),
          const SizedBox(height: 16),
          _buildAllocationCard(report),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard(dynamic report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '收益概览',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('总收益', '${(report.totalReturn * 100).toStringAsFixed(2)}%'),
                _buildMetricItem('年化收益', '${(report.annualizedReturn * 100).toStringAsFixed(2)}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsCard(dynamic report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '风险指标',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('最大回撤'),
              trailing: Text('${(report.maxDrawdown * 100).toStringAsFixed(2)}%'),
            ),
            ListTile(
              title: const Text('夏普比率'),
              trailing: Text(report.sharpeRatio.toStringAsFixed(2)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAllocationCard(dynamic report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '资产配置',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (report.allocations.isEmpty)
              const Center(child: Text('暂无配置数据'))
            else
              ...report.allocations.map((a) => ListTile(
                title: Text(a.assetName),
                subtitle: Text(a.assetType),
                trailing: Text('${(a.percentage * 100).toStringAsFixed(1)}%'),
              )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }
}
