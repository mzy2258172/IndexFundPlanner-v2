import '../../domain/entities/portfolio.dart';

/// 投资组合仓储接口
abstract class PortfolioRepository {
  Future<List<Portfolio>> getAllPortfolios();
  Future<Portfolio?> getPortfolioById(String id);
  Future<void> savePortfolio(Portfolio portfolio);
  Future<void> deletePortfolio(String id);
}
