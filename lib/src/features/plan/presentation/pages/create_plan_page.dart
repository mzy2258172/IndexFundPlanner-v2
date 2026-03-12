import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/plan.dart';
import '../../domain/services/portfolio_recommendation.dart';
import '../providers/plan_provider.dart';
import '../../../user/presentation/providers/user_provider.dart';
import '../../../user/domain/entities/user.dart';

class CreatePlanPage extends ConsumerStatefulWidget {
  final String? fundCode;
  
  const CreatePlanPage({super.key, this.fundCode});
  
  @override
  ConsumerState<CreatePlanPage> createState() => _CreatePlanPageState();
}

class _CreatePlanPageState extends ConsumerState<CreatePlanPage> {
  int _currentStep = 0;
  
  // Step 1: 目标设定
  PlanGoalType _selectedGoal = PlanGoalType.wealth;
  final _targetAmountController = TextEditingController(text: '100000');
  final _initialCapitalController = TextEditingController(text: '0');
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365 * 5));
  
  // Step 2: 组合选择
  int _selectedPortfolioIndex = 1; // 默认选择均衡方案
  List<Portfolio>? _recommendedPortfolios;
  
  // Step 3: 定投设置
  String _frequency = 'monthly';
  int _investmentDay = 10;
  late TextEditingController _monthlyAmountController;
  String _strategy = 'normal';
  
  bool _loading = false;
  
  @override
  void initState() {
    super.initState();
    _monthlyAmountController = TextEditingController(text: '2000');
    _targetAmountController.addListener(_updateMonthlySuggestion);
  }
  
  @override
  void dispose() {
    _targetAmountController.dispose();
    _initialCapitalController.dispose();
    _monthlyAmountController.dispose();
    super.dispose();
  }
  
  void _updateMonthlySuggestion() {
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 100000;
    final initialCapital = double.tryParse(_initialCapitalController.text) ?? 0;
    final months = _targetDate.difference(DateTime.now()).inDays ~/ 30;
    
    final userRisk = ref.read(userRiskLevelProvider);
    final suggested = PortfolioRecommendationEngine.calculateSuggestedMonthlyInvestment(
      targetAmount: targetAmount,
      months: months,
      initialCapital: initialCapital,
      riskLevel: userRisk,
    );
    
    _monthlyAmountController.text = suggested.toStringAsFixed(0);
  }
  
  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      
      if (_currentStep == 1) {
        // 生成推荐组合
        final riskLevel = ref.read(userRiskLevelProvider);
        final amount = double.tryParse(_monthlyAmountController.text) ?? 2000;
        _recommendedPortfolios = PortfolioRecommendationEngine.generateRecommendedPortfolios(
          riskLevel: riskLevel,
          totalAmount: amount * 12,
        );
      }
    } else {
      _createPlan();
    }
  }
  
  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }
  
  Future<void> _createPlan() async {
    setState(() => _loading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }
      
      final portfolio = _recommendedPortfolios?[_selectedPortfolioIndex];
      
      final sipPlan = SipPlan(
        id: const Uuid().v4(),
        frequency: _frequency,
        investmentDay: _investmentDay,
        amount: double.parse(_monthlyAmountController.text),
        strategy: _strategy,
      );
      
      final plan = await ref.read(planNotifierProvider.notifier).createPlan(
        userId: user.id,
        name: '${_selectedGoal.displayName}计划',
        goalType: _selectedGoal,
        targetAmount: double.parse(_targetAmountController.text),
        initialCapital: double.parse(_initialCapitalController.text),
        targetDate: _targetDate,
        monthlyInvestment: double.parse(_monthlyAmountController.text),
        riskLevel: user.riskLevel,
        portfolio: portfolio,
        sipPlan: sipPlan,
      );
      
      if (plan != null && mounted) {
        // 刷新计划列表
        ref.invalidate(userPlansProvider);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('投资计划创建成功！')),
        );
        context.go('/plan/${plan.id}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建投资计划'),
      ),
      body: Column(
        children: [
          // 步骤指示器
          _buildStepIndicator(),
          
          // 内容区域
          Expanded(
            child: IndexedStack(
              index: _currentStep,
              children: [
                _buildGoalStep(),
                _buildPortfolioStep(),
                _buildSipStep(),
              ],
            ),
          ),
          
          // 底部按钮
          _buildBottomButtons(),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index <= _currentStep;
          final isCurrent = index == _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        child: Center(
                          child: isActive && !isCurrent
                            ? Icon(
                                Icons.check,
                                size: 18,
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ['设定目标', '选择组合', '定投设置'][index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 24),
                      color: index < _currentStep
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
  
  // Step 1: 目标设定
  Widget _buildGoalStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择投资目标',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // 目标类型选择
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: PlanGoalType.values.map((type) {
              final isSelected = _selectedGoal == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedGoal = type),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 56) / 3,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  ),
                  child: Column(
                    children: [
                      Text(type.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 8),
                      Text(
                        type.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // 目标金额
          TextField(
            controller: _targetAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '目标金额',
              suffixText: '元',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 初始本金
          TextField(
            controller: _initialCapitalController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '初始本金（可选）',
              suffixText: '元',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 目标日期
          ListTile(
            title: const Text('目标达成日期'),
            subtitle: Text(
              '${_targetDate.year}年${_targetDate.month}月${_targetDate.day}日',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 目标说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selectedGoal.emoji} ${_selectedGoal.displayName}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedGoal.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
    );
    
    if (date != null) {
      setState(() => _targetDate = date);
      _updateMonthlySuggestion();
    }
  }
  
  // Step 2: 组合选择
  Widget _buildPortfolioStep() {
    if (_recommendedPortfolios == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '根据您的风险偏好推荐以下组合',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // 组合方案选择
          ..._recommendedPortfolios!.asMap().entries.map((entry) {
            final index = entry.key;
            final portfolio = entry.value;
            final isSelected = _selectedPortfolioIndex == index;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPortfolioIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            portfolio.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '预期年化收益: ${portfolio.expectedReturnMin?.toStringAsFixed(1) ?? 0}% - ${portfolio.expectedReturnMax?.toStringAsFixed(1) ?? 0}%',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // 配置明细
                      ...portfolio.allocations.map((allocation) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                allocation.fundName,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              '${allocation.ratio.toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
            );
          }),
          
          const SizedBox(height: 16),
          
          // 手动调整提示
          OutlinedButton.icon(
            onPressed: () {
              // TODO: 手动调整组合
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('自定义组合功能开发中')),
              );
            },
            icon: const Icon(Icons.edit),
            label: const Text('自定义组合'),
          ),
        ],
      ),
    );
  }
  
  // Step 3: 定投设置
  Widget _buildSipStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '设置定投计划',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          
          // 定投频率
          Text(
            '定投频率',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'weekly', label: Text('每周')),
              ButtonSegment(value: 'biweekly', label: Text('每两周')),
              ButtonSegment(value: 'monthly', label: Text('每月')),
            ],
            selected: {_frequency},
            onSelectionChanged: (set) => setState(() => _frequency = set.first),
          ),
          
          const SizedBox(height: 16),
          
          // 扣款日期
          Text(
            '扣款日期',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 5, 10, 15, 20, 25].map((day) {
              final isSelected = _investmentDay == day;
              return GestureDetector(
                onTap: () => setState(() => _investmentDay = day),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: Center(
                    child: Text(
                      '$day日',
                      style: TextStyle(
                        color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // 定投金额
          TextField(
            controller: _monthlyAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '每月定投金额',
              suffixText: '元',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 定投策略
          Text(
            '定投策略',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          
          _buildStrategyOption(
            'normal',
            '普通定投',
            '每期固定金额，长期持有',
          ),
          _buildStrategyOption(
            'ma',
            '均线策略',
            '低估多投，高估少投',
          ),
          _buildStrategyOption(
            'value_avg',
            '价值平均',
            '保持市值稳定增长',
          ),
          
          const SizedBox(height: 24),
          
          // 计划摘要
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '计划摘要',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSummaryRow(
                  '目标金额',
                  '¥${_targetAmountController.text}',
                ),
                _buildSummaryRow(
                  '每月定投',
                  '¥${_monthlyAmountController.text}',
                ),
                _buildSummaryRow(
                  '定投频率',
                  _frequency == 'monthly' ? '每月' 
                    : _frequency == 'weekly' ? '每周' : '每两周',
                ),
                _buildSummaryRow(
                  '预计达成',
                  '${_targetDate.year}年${_targetDate.month}月',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStrategyOption(String value, String title, String subtitle) {
    final isSelected = _strategy == value;
    
    return RadioListTile<String>(
      value: value,
      groupValue: _strategy,
      onChanged: (v) => setState(() => _strategy = v!),
      title: Text(title),
      subtitle: Text(subtitle),
      dense: true,
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomButtons() {
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
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _prevStep,
                  child: const Text('上一步'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 16),
            Expanded(
              flex: _currentStep > 0 ? 1 : 2,
              child: FilledButton(
                onPressed: _loading ? null : _nextStep,
                child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < 2 ? '下一步' : '创建计划'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
