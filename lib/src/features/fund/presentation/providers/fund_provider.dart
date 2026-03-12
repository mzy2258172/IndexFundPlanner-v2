import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/fund.dart';
import '../../domain/repositories/fund_repository.dart';
import '../../data/repositories/fund_repository_impl.dart';

// Re-export from repository impl
export '../../data/repositories/fund_repository_impl.dart';
export '../../domain/repositories/fund_repository.dart';

/// 基金列表状态
class FundListState {
  final List<Fund> funds;
  final bool isLoading;
  final String? error;
  final String type;
  
  const FundListState({
    this.funds = const [],
    this.isLoading = false,
    this.error,
    this.type = 'all',
  });
  
  FundListState copyWith({
    List<Fund>? funds,
    bool? isLoading,
    String? error,
    String? type,
  }) {
    return FundListState(
      funds: funds ?? this.funds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      type: type ?? this.type,
    );
  }
}

/// 基金列表 Notifier
class FundListNotifier extends StateNotifier<FundListState> {
  final FundRepository _repository;
  
  FundListNotifier(this._repository) : super(const FundListState());
  
  /// 加载指数基金列表
  Future<void> loadIndexFunds({String type = 'all', bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null, type: type);
    
    try {
      final funds = await _repository.getIndexFunds(
        type: type,
        useCache: !forceRefresh,
      );
      state = state.copyWith(funds: funds, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 刷新列表
  Future<void> refresh() async {
    await loadIndexFunds(type: state.type, forceRefresh: true);
  }
}

/// 基金详情状态
class FundDetailState {
  final FundDetail? detail;
  final bool isLoading;
  final String? error;
  
  const FundDetailState({
    this.detail,
    this.isLoading = false,
    this.error,
  });
  
  FundDetailState copyWith({
    FundDetail? detail,
    bool? isLoading,
    String? error,
  }) {
    return FundDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 基金详情 Notifier
class FundDetailNotifier extends StateNotifier<FundDetailState> {
  final FundRepository _repository;
  
  FundDetailNotifier(this._repository) : super(const FundDetailState());
  
  /// 加载基金详情
  Future<void> loadFundDetail(String fundCode, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final detail = await _repository.getFundDetail(
        fundCode,
        useCache: !forceRefresh,
      );
      
      if (detail != null) {
        state = state.copyWith(detail: detail, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '未找到基金信息',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 刷新详情
  Future<void> refresh(String fundCode) async {
    await loadFundDetail(fundCode, forceRefresh: true);
  }
}

/// 搜索状态
class FundSearchState {
  final List<Fund> results;
  final bool isLoading;
  final String? error;
  final String keyword;
  
  const FundSearchState({
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.keyword = '',
  });
  
  FundSearchState copyWith({
    List<Fund>? results,
    bool? isLoading,
    String? error,
    String? keyword,
  }) {
    return FundSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      keyword: keyword ?? this.keyword,
    );
  }
}

/// 搜索 Notifier
class FundSearchNotifier extends StateNotifier<FundSearchState> {
  final FundRepository _repository;
  
  FundSearchNotifier(this._repository) : super(const FundSearchState());
  
  /// 搜索基金
  Future<void> search(String keyword, {bool forceRefresh = false}) async {
    if (keyword.trim().isEmpty) {
      state = const FundSearchState();
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null, keyword: keyword);
    
    try {
      final results = await _repository.searchFunds(
        keyword,
        useCache: !forceRefresh,
      );
      state = state.copyWith(results: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
  
  /// 清除搜索结果
  void clear() {
    state = const FundSearchState();
  }
}

/// 净值历史状态
class NetValueHistoryState {
  final List<FundNetValue> history;
  final bool isLoading;
  final String? error;
  
  const NetValueHistoryState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });
  
  NetValueHistoryState copyWith({
    List<FundNetValue>? history,
    bool? isLoading,
    String? error,
  }) {
    return NetValueHistoryState(
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 净值历史 Notifier
class NetValueHistoryNotifier extends StateNotifier<NetValueHistoryState> {
  final FundRepository _repository;
  
  NetValueHistoryNotifier(this._repository) : super(const NetValueHistoryState());
  
  /// 加载净值历史
  Future<void> loadHistory(String fundCode, {int days = 30, bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final history = await _repository.getFundNetValueHistory(
        fundCode,
        days: days,
        useCache: !forceRefresh,
      );
      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// ==================== Providers ====================

/// 基金列表 Provider
final fundListNotifierProvider = StateNotifierProvider<FundListNotifier, FundListState>((ref) {
  final repository = ref.watch(fundRepositoryProvider);
  return FundListNotifier(repository);
});

/// 基金详情 Provider
final fundDetailNotifierProvider = StateNotifierProvider.family<FundDetailNotifier, FundDetailState, String>((ref, fundCode) {
  final repository = ref.watch(fundRepositoryProvider);
  return FundDetailNotifier(repository);
});

/// 搜索 Provider
final fundSearchNotifierProvider = StateNotifierProvider<FundSearchNotifier, FundSearchState>((ref) {
  final repository = ref.watch(fundRepositoryProvider);
  return FundSearchNotifier(repository);
});

/// 净值历史 Provider
final netValueHistoryNotifierProvider = StateNotifierProvider.family<NetValueHistoryNotifier, NetValueHistoryState, String>((ref, fundCode) {
  final repository = ref.watch(fundRepositoryProvider);
  return NetValueHistoryNotifier(repository);
});

/// 热门基金 Provider
final hotFundsProvider = FutureProvider<List<Fund>>((ref) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getHotIndexFunds();
});

/// 宽基指数基金 Provider
final broadIndexFundsProvider = FutureProvider<List<Fund>>((ref) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getIndexFunds(type: 'broad');
});

/// 行业指数基金 Provider
final sectorIndexFundsProvider = FutureProvider<List<Fund>>((ref) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getIndexFunds(type: 'sector');
});

/// 简单搜索 Provider（用于一次性搜索）
final fundSearchProvider = FutureProvider.family<List<Fund>, String>((ref, keyword) async {
  if (keyword.trim().isEmpty) return [];
  final repository = ref.watch(fundRepositoryProvider);
  return repository.searchFunds(keyword);
});

/// 简单详情 Provider（用于一次性获取）
final fundDetailProvider = FutureProvider.family<FundDetail?, String>((ref, fundCode) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getFundDetail(fundCode);
});

/// 简单净值历史 Provider
final netValueHistoryProvider = FutureProvider.family<List<FundNetValue>, String>((ref, fundCode) async {
  final repository = ref.watch(fundRepositoryProvider);
  return repository.getFundNetValueHistory(fundCode);
});
