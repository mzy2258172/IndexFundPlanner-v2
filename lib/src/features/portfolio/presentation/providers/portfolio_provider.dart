import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/portfolio.dart';
import '../../data/repositories/portfolio_repository_impl.dart';

/// 持仓状态
sealed class PortfolioState {
  const PortfolioState();
}

class PortfolioInitial extends PortfolioState {
  const PortfolioInitial();
}

class PortfolioLoading extends PortfolioState {
  const PortfolioLoading();
}

class PortfolioLoaded extends PortfolioState {
  final List<Portfolio> portfolios;
  const PortfolioLoaded(this.portfolios);
}

class PortfolioError extends PortfolioState {
  final String message;
  const PortfolioError(this.message);
}

/// 投资组合仓储 Provider
final portfolioRepositoryProvider = Provider<PortfolioRepositoryImpl>((ref) {
  return PortfolioRepositoryImpl();
});

/// 投资组合列表 Provider
final portfolioListProvider = StateNotifierProvider<PortfolioNotifier, PortfolioState>((ref) {
  final repository = ref.watch(portfolioRepositoryProvider);
  return PortfolioNotifier(repository);
});

/// 当前选中的投资组合
final selectedPortfolioProvider = StateProvider<Portfolio?>((ref) => null);

/// 投资组合详情 Provider
final portfolioDetailProvider = FutureProvider.family<Portfolio?, String>((ref, id) async {
  final repository = ref.watch(portfolioRepositoryProvider);
  return repository.getPortfolioById(id);
});

/// 持仓统计 Provider
final portfolioStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(portfolioListProvider);
  
  if (state is! PortfolioLoaded) {
    return {
      'totalInvestment': 0.0,
      'totalValue': 0.0,
      'totalProfit': 0.0,
      'totalReturnRate': 0.0,
      'todayProfit': 0.0,
      'itemCount': 0,
    };
  }
  
  final portfolios = state.portfolios;
  double totalInvestment = 0;
  double totalValue = 0;
  int itemCount = 0;
  
  for (final portfolio in portfolios) {
    totalInvestment += portfolio.totalInvestment;
    totalValue += portfolio.totalValue;
    itemCount += portfolio.items.length;
  }
  
  final totalProfit = totalValue - totalInvestment;
  final totalReturnRate = totalInvestment > 0 ? totalProfit / totalInvestment : 0.0;
  
  return {
    'totalInvestment': totalInvestment,
    'totalValue': totalValue,
    'totalProfit': totalProfit,
    'totalReturnRate': totalReturnRate,
    'todayProfit': totalValue * 0.001, // 模拟今日收益
    'itemCount': itemCount,
  };
});

/// 持仓分布 Provider（按基金类型）
final portfolioDistributionProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(portfolioListProvider);
  
  if (state is! PortfolioLoaded) {
    return {};
  }
  
  final portfolios = state.portfolios;
  final distribution = <String, double>{};
  
  for (final portfolio in portfolios) {
    for (final item in portfolio.items) {
      // 根据基金代码判断类型
      String type = _getFundType(item.fundCode);
      distribution[type] = (distribution[type] ?? 0) + item.currentValue;
    }
  }
  
  return distribution;
});

String _getFundType(String code) {
  // 简单的基金类型判断
  if (code.startsWith('51')) {
    if (code.contains('300') || code.contains('500') || code.contains('800')) {
      return '宽基指数';
    } else if (code.contains('医药') || code.contains('消费')) {
      return '行业指数';
    }
  } else if (code.startsWith('159')) {
    return '行业指数';
  } else if (code.startsWith('00')) {
    return '主动基金';
  }
  return '其他';
}

class PortfolioNotifier extends StateNotifier<PortfolioState> {
  final PortfolioRepositoryImpl _repository;
  
  PortfolioNotifier(this._repository) : super(const PortfolioInitial()) {
    loadPortfolios();
  }
  
  /// 加载所有投资组合
  Future<void> loadPortfolios() async {
    state = const PortfolioLoading();
    try {
      final portfolios = await _repository.getAllPortfolios();
      state = PortfolioLoaded(portfolios);
    } catch (e) {
      state = PortfolioError(e.toString());
    }
  }
  
  /// 添加投资组合
  Future<void> addPortfolio(Portfolio portfolio) async {
    try {
      await _repository.savePortfolio(portfolio);
      await loadPortfolios();
    } catch (e) {
      state = PortfolioError(e.toString());
    }
  }
  
  /// 更新投资组合
  Future<void> updatePortfolio(Portfolio portfolio) async {
    try {
      await _repository.savePortfolio(portfolio.copyWith(
        updatedAt: DateTime.now(),
      ));
      await loadPortfolios();
    } catch (e) {
      state = PortfolioError(e.toString());
    }
  }
  
  /// 删除投资组合
  Future<void> deletePortfolio(String id) async {
    try {
      await _repository.deletePortfolio(id);
      await loadPortfolios();
    } catch (e) {
      state = PortfolioError(e.toString());
    }
  }
  
  /// 添加持仓项目到组合
  Future<void> addPortfolioItem(String portfolioId, PortfolioItem item) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    
    final portfolio = currentState.portfolios.firstWhere(
      (p) => p.id == portfolioId,
      orElse: () => throw Exception('投资组合不存在'),
    );
    
    final updatedItems = [...portfolio.items, item];
    await updatePortfolio(portfolio.copyWith(items: updatedItems));
  }
  
  /// 更新持仓项目
  Future<void> updatePortfolioItem(String portfolioId, int itemIndex, PortfolioItem item) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    
    final portfolio = currentState.portfolios.firstWhere(
      (p) => p.id == portfolioId,
      orElse: () => throw Exception('投资组合不存在'),
    );
    
    if (itemIndex < 0 || itemIndex >= portfolio.items.length) return;
    
    final updatedItems = List<PortfolioItem>.from(portfolio.items);
    updatedItems[itemIndex] = item;
    await updatePortfolio(portfolio.copyWith(items: updatedItems));
  }
  
  /// 删除持仓项目
  Future<void> removePortfolioItem(String portfolioId, int itemIndex) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    
    final portfolio = currentState.portfolios.firstWhere(
      (p) => p.id == portfolioId,
      orElse: () => throw Exception('投资组合不存在'),
    );
    
    if (itemIndex < 0 || itemIndex >= portfolio.items.length) return;
    
    final updatedItems = List<PortfolioItem>.from(portfolio.items);
    updatedItems.removeAt(itemIndex);
    await updatePortfolio(portfolio.copyWith(items: updatedItems));
  }
  
  /// 更新持仓项目当前价格（用于收益计算）
  Future<void> updateItemPrice(String portfolioId, int itemIndex, double newPrice) async {
    final currentState = state;
    if (currentState is! PortfolioLoaded) return;
    
    final portfolio = currentState.portfolios.firstWhere(
      (p) => p.id == portfolioId,
      orElse: () => throw Exception('投资组合不存在'),
    );
    
    if (itemIndex < 0 || itemIndex >= portfolio.items.length) return;
    
    final oldItem = portfolio.items[itemIndex];
    final updatedItem = PortfolioItem(
      fundCode: oldItem.fundCode,
      fundName: oldItem.fundName,
      investmentAmount: oldItem.investmentAmount,
      currentPrice: newPrice,
      shares: oldItem.shares,
      purchaseDate: oldItem.purchaseDate,
    );
    
    await updatePortfolioItem(portfolioId, itemIndex, updatedItem);
  }
}
