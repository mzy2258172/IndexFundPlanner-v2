import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/fund.dart';
import '../providers/fund_provider.dart';

class FundListPage extends ConsumerStatefulWidget {
  const FundListPage({super.key});
  
  @override
  ConsumerState<FundListPage> createState() => _FundListPageState();
}

class _FundListPageState extends ConsumerState<FundListPage> 
  with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    
    // 初始加载
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(fundListNotifierProvider.notifier).loadIndexFunds(type: 'all');
    });
  }
  
  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    
    final types = ['all', 'broad', 'sector', 'theme'];
    final type = types[_tabController.index];
    ref.read(fundListNotifierProvider.notifier).loadIndexFunds(type: type);
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('指数基金市场'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '宽基'),
            Tab(text: '行业'),
            Tab(text: '主题'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索基金代码或名称',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                        ref.read(fundSearchNotifierProvider.notifier).clear();
                      },
                    )
                  : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref.read(fundSearchNotifierProvider.notifier).search(value);
                }
              },
            ),
          ),
          
          // 基金列表
          Expanded(
            child: _searchQuery.isNotEmpty
              ? _buildSearchResults()
              : _buildFundTabs(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults() {
    final searchState = ref.watch(fundSearchNotifierProvider);
    
    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (searchState.error != null) {
      return _buildErrorWidget(searchState.error!, () {
        ref.read(fundSearchNotifierProvider.notifier).search(_searchQuery, forceRefresh: true);
      });
    }
    
    final funds = searchState.results;
    if (funds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48),
            SizedBox(height: 16),
            Text('未找到相关基金'),
          ],
        ),
      );
    }
    
    return _buildFundList(funds);
  }
  
  Widget _buildFundTabs() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildFundTab('all'),
        _buildFundTab('broad'),
        _buildFundTab('sector'),
        _buildFundTab('theme'),
      ],
    );
  }
  
  Widget _buildFundTab(String type) {
    final state = ref.watch(fundListNotifierProvider);
    
    if (state.isLoading && state.funds.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state.error != null && state.funds.isEmpty) {
      return _buildErrorWidget(state.error!, () {
        ref.read(fundListNotifierProvider.notifier).loadIndexFunds(type: type, forceRefresh: true);
      });
    }
    
    final funds = state.funds;
    if (funds.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48),
            SizedBox(height: 16),
            Text('暂无数据'),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(fundListNotifierProvider.notifier).refresh();
      },
      child: _buildFundList(funds),
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
  
  Widget _buildFundList(List<Fund> funds) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: funds.length,
      itemBuilder: (context, index) {
        final fund = funds[index];
        return _buildFundCard(context, fund);
      },
    );
  }
  
  Widget _buildFundCard(BuildContext context, Fund fund) {
    final isUp = fund.dayChangeRate >= 0;
    final color = isUp ? Colors.red : Colors.green;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/fund/${fund.code}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 基金代码标签
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        fund.code.substring(0, 3),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 基金信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                fund.name,
                                style: Theme.of(context).textTheme.titleSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                fund.type,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fund.code,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 涨跌幅
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isUp ? '+' : ''}${fund.dayChangeRate.toStringAsFixed(2)}%',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        fund.currentPrice.toStringAsFixed(4),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // 收益数据
              Row(
                children: [
                  _buildReturnBadge(context, '近1年', fund.return1y),
                  const SizedBox(width: 12),
                  _buildReturnBadge(context, '近3年', fund.return3y),
                  const SizedBox(width: 12),
                  if (fund.scale != null)
                    _buildInfoBadge(context, '规模', '${fund.scale!.toStringAsFixed(0)}亿'),
                  if (fund.riskLevel != null) ...[
                    const SizedBox(width: 12),
                    _buildInfoBadge(context, '风险', fund.riskLevelName),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReturnBadge(BuildContext context, String label, double? value) {
    if (value == null) return const SizedBox.shrink();
    
    final isUp = value >= 0;
    final color = isUp ? Colors.red : Colors.green;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${isUp ? '+' : ''}${value.toStringAsFixed(2)}%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoBadge(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '筛选条件',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // 基金公司
            Text(
              '基金公司',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['全部', '华夏', '易方达', '华泰柏瑞', '国泰']
                .map((c) => FilterChip(
                  label: Text(c),
                  selected: c == '全部',
                  onSelected: (selected) {},
                ))
                .toList(),
            ),
            
            const SizedBox(height: 16),
            
            // 基金规模
            Text(
              '基金规模',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['全部', '<10亿', '10-50亿', '50-100亿', '>100亿']
                .map((c) => FilterChip(
                  label: Text(c),
                  selected: c == '全部',
                  onSelected: (selected) {},
                ))
                .toList(),
            ),
            
            const SizedBox(height: 24),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('重置'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('确定'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
