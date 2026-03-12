import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/portfolio.dart';
import '../providers/portfolio_provider.dart';

/// 添加持仓页面
class AddHoldingPage extends ConsumerStatefulWidget {
  final String? portfolioId;
  
  const AddHoldingPage({super.key, this.portfolioId});

  @override
  ConsumerState<AddHoldingPage> createState() => _AddHoldingPageState();
}

class _AddHoldingPageState extends ConsumerState<AddHoldingPage> {
  final _formKey = GlobalKey<FormState>();
  final _fundCodeController = TextEditingController();
  final _fundNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _priceController = TextEditingController();
  final _sharesController = TextEditingController();
  
  DateTime _purchaseDate = DateTime.now();
  bool _isLoading = false;
  bool _autoCalculateShares = true;

  @override
  void dispose() {
    _fundCodeController.dispose();
    _fundNameController.dispose();
    _amountController.dispose();
    _priceController.dispose();
    _sharesController.dispose();
    super.dispose();
  }

  void _calculateShares() {
    if (!_autoCalculateShares) return;
    
    final amount = double.tryParse(_amountController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;
    
    if (amount > 0 && price > 0) {
      final shares = amount / price;
      _sharesController.text = shares.toStringAsFixed(2);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final item = PortfolioItem(
        fundCode: _fundCodeController.text.trim(),
        fundName: _fundNameController.text.trim(),
        investmentAmount: double.parse(_amountController.text),
        currentPrice: double.parse(_priceController.text),
        shares: double.parse(_sharesController.text),
        purchaseDate: _purchaseDate,
      );
      
      final portfolioState = ref.read(portfolioListProvider);
      
      if (widget.portfolioId != null) {
        // 添加到现有组合
        await ref.read(portfolioListProvider.notifier)
            .addPortfolioItem(widget.portfolioId!, item);
      } else if (portfolioState is PortfolioLoaded && portfolioState.portfolios.isNotEmpty) {
        // 添加到第一个组合
        await ref.read(portfolioListProvider.notifier)
            .addPortfolioItem(portfolioState.portfolios.first.id, item);
      } else {
        // 创建新组合并添加
        final portfolio = Portfolio(
          id: const Uuid().v4(),
          name: '我的投资组合',
          items: [item],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await ref.read(portfolioListProvider.notifier).addPortfolio(portfolio);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('持仓添加成功')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('添加失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加持仓'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 基金代码
            TextFormField(
              controller: _fundCodeController,
              decoration: const InputDecoration(
                labelText: '基金代码',
                hintText: '例如: 510300',
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入基金代码';
                }
                if (value.length != 6) {
                  return '基金代码应为6位';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 基金名称
            TextFormField(
              controller: _fundNameController,
              decoration: const InputDecoration(
                labelText: '基金名称',
                hintText: '例如: 沪深300ETF',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入基金名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 投资金额
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '投资金额',
                hintText: '买入金额（元）',
                prefixIcon: Icon(Icons.attach_money),
                suffixText: '元',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateShares(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入投资金额';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return '请输入有效金额';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 买入价格
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: '买入净值',
                hintText: '买入时的单位净值',
                prefixIcon: Icon(Icons.show_chart),
                suffixText: '元',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => _calculateShares(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入买入净值';
                }
                final price = double.tryParse(value);
                if (price == null || price <= 0) {
                  return '请输入有效净值';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // 持仓份额
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _sharesController,
                    decoration: const InputDecoration(
                      labelText: '持仓份额',
                      hintText: '持有份额',
                      prefixIcon: Icon(Icons.pie_chart),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入份额';
                      }
                      final shares = double.tryParse(value);
                      if (shares == null || shares <= 0) {
                        return '请输入有效份额';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _autoCalculateShares ? Icons.lock : Icons.lock_open,
                    color: _autoCalculateShares 
                        ? Theme.of(context).colorScheme.primary 
                        : Theme.of(context).colorScheme.outline,
                  ),
                  tooltip: _autoCalculateShares ? '自动计算' : '手动输入',
                  onPressed: () {
                    setState(() {
                      _autoCalculateShares = !_autoCalculateShares;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _autoCalculateShares ? '份额将自动计算（金额÷净值）' : '手动输入份额',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 24),
            
            // 买入日期
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('买入日期'),
              subtitle: Text(
                '${_purchaseDate.year}-${_purchaseDate.month.toString().padLeft(2, '0')}-${_purchaseDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectDate,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 32),
            
            // 提示信息
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '提示',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 投资金额 = 买入净值 × 持仓份额\n'
                    '• 收益率 = (当前净值 - 买入净值) ÷ 买入净值\n'
                    '• 当前市值将根据最新净值自动更新',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
