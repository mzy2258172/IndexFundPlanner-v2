import 'package:hive/hive.dart';
import '../../domain/entities/portfolio.dart';
import '../../domain/repositories/portfolio_repository.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  static const String _boxName = 'portfolios';
  
  Future<Box<Map>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Map>(_boxName);
    }
    return Hive.box<Map>(_boxName);
  }
  
  @override
  Future<List<Portfolio>> getAllPortfolios() async {
    final box = await _getBox();
    return box.values.map((e) => _fromMap(e)).toList();
  }
  
  @override
  Future<Portfolio?> getPortfolioById(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    return data != null ? _fromMap(data) : null;
  }
  
  @override
  Future<void> savePortfolio(Portfolio portfolio) async {
    final box = await _getBox();
    await box.put(portfolio.id, _toMap(portfolio));
  }
  
  @override
  Future<void> deletePortfolio(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
  
  Map<String, dynamic> _toMap(Portfolio portfolio) {
    return {
      'id': portfolio.id,
      'name': portfolio.name,
      'description': portfolio.description,
      'items': portfolio.items.map((e) => {
        'fundCode': e.fundCode,
        'fundName': e.fundName,
        'investmentAmount': e.investmentAmount,
        'currentPrice': e.currentPrice,
        'shares': e.shares,
        'purchaseDate': e.purchaseDate.toIso8601String(),
      }).toList(),
      'createdAt': portfolio.createdAt.toIso8601String(),
      'updatedAt': portfolio.updatedAt.toIso8601String(),
    };
  }
  
  Portfolio _fromMap(Map<dynamic, dynamic> map) {
    return Portfolio(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      items: (map['items'] as List?)?.map((e) => PortfolioItem(
        fundCode: e['fundCode'],
        fundName: e['fundName'],
        investmentAmount: e['investmentAmount'],
        currentPrice: e['currentPrice'],
        shares: e['shares'],
        purchaseDate: DateTime.parse(e['purchaseDate']),
      )).toList() ?? [],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}
