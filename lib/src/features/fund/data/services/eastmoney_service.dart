import 'dart:convert';
import 'package:dio/dio.dart';
import '../domain/entities/fund.dart';

/// 天天基金API服务
class EastMoneyService {
  final Dio _dio;
  
  // 天天基金API基础URL
  static const String _fundSuggestUrl = 'https://fundsuggest.eastmoney.com/FundSearch/api/FundSearchAPI.ashx';
  static const String _fundDetailUrl = 'https://fundgz.eastmoney.com/js';
  static const String _fundNetValueUrl = 'https://api.fund.eastmoney.com/f10/lsjz';
  static const String _fundRankUrl = 'https://fund.eastmoney.com/data/rankhandler.aspx';
  static const String _fundInfoUrl = 'https://fund.eastmoney.com/pingzhongdata';
  
  EastMoneyService(this._dio);
  
  /// 搜索基金
  /// 
  /// [keyword] 搜索关键词（基金代码或名称）
  /// [page] 页码，从1开始
  /// [size] 每页数量
  Future<List<Fund>> searchFunds({
    String? keyword,
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        _fundSuggestUrl,
        queryParameters: {
          'm': '1',
          'key': keyword ?? '',
          'pagesize': size,
          'pageindex': page,
          '_': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          headers: {
            'Referer': 'https://fund.eastmoney.com/',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      return _parseSearchResponse(response.data as String);
    } on DioException catch (e) {
      throw _handleDioError(e, '搜索基金');
    } catch (e) {
      throw Exception('搜索基金失败: $e');
    }
  }
  
  /// 获取基金详情
  /// 
  /// [fundCode] 基金代码
  Future<FundDetail?> getFundDetail(String fundCode) async {
    try {
      // 并行获取基金实时数据和净值历史
      final results = await Future.wait([
        _getFundRealTimeData(fundCode),
        getNetValueHistory(fundCode, days: 30),
        _getFundInfo(fundCode),
      ]);
      
      final fund = results[0] as Fund?;
      final netValueHistory = results[1] as List<FundNetValue>;
      final fundInfo = results[2] as Map<String, dynamic>?;
      
      if (fund == null) return null;
      
      // 合并信息
      final mergedFund = fund.copyWith(
        scale: fundInfo?['scale'] as double? ?? fund.scale,
        fundCompany: fundInfo?['fundCompany'] as String? ?? fund.fundCompany,
        establishDate: fundInfo?['establishDate'] as DateTime? ?? fund.establishDate,
        trackingIndex: fundInfo?['trackingIndex'] as String? ?? fund.trackingIndex,
        managementFee: fundInfo?['managementFee'] as double? ?? fund.managementFee,
        custodyFee: fundInfo?['custodyFee'] as double? ?? fund.custodyFee,
        return1y: fundInfo?['return1y'] as double? ?? fund.return1y,
        return3y: fundInfo?['return3y'] as double? ?? fund.return3y,
        return5y: fundInfo?['return5y'] as double? ?? fund.return5y,
        riskLevel: fundInfo?['riskLevel'] as int? ?? fund.riskLevel,
      );
      
      return FundDetail(
        fund: mergedFund,
        netValueHistory: netValueHistory,
        manager: fundInfo?['manager'] as FundManager?,
      );
    } on DioException catch (e) {
      throw _handleDioError(e, '获取基金详情');
    } catch (e) {
      throw Exception('获取基金详情失败: $e');
    }
  }
  
  /// 获取基金净值历史
  /// 
  /// [fundCode] 基金代码
  /// [days] 天数
  /// [page] 页码
  Future<List<FundNetValue>> getNetValueHistory(
    String fundCode, {
    int days = 30,
    int page = 1,
  }) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days + 10)); // 多取几天确保足够
      
      final response = await _dio.get(
        _fundNetValueUrl,
        queryParameters: {
          'fund_code': fundCode,
          'page_index': page,
          'page_size': days,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
        options: Options(
          headers: {
            'Referer': 'https://fund.eastmoney.com/',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
        ),
      );
      
      return _parseNetValueResponse(fundCode, response.data);
    } on DioException catch (e) {
      throw _handleDioError(e, '获取净值历史');
    } catch (e) {
      throw Exception('获取净值历史失败: $e');
    }
  }
  
  /// 获取指数基金列表
  /// 
  /// [type] 类型：broad(宽基), sector(行业), theme(主题), all(全部)
  /// [sort] 排序字段：rzdf(近1年收益率), 3yzf(近3年收益率), 6yzf(近6年收益率)
  /// [page] 页码
  /// [size] 每页数量
  Future<List<Fund>> getIndexFunds({
    String type = 'all',
    String sort = 'rzdf',
    int page = 1,
    int size = 20,
  }) async {
    try {
      // tp: 宽基=b, 行业=h, 主题=z, 全部=all
      String tp = '';
      switch (type) {
        case 'broad':
          tp = 'b';
          break;
        case 'sector':
          tp = 'h';
          break;
        case 'theme':
          tp = 'z';
          break;
        default:
          tp = 'all';
      }
      
      final response = await _dio.get(
        _fundRankUrl,
        queryParameters: {
          'op': 'ph',
          'dt': 'kf',
          'ft': 'zq', // 指数基金
          'rs': '',
          'gs': '0',
          'sc': sort,
          'st': 'desc',
          'sd': _formatDate(DateTime.now().subtract(const Duration(days: 365 * 3))),
          'ed': _formatDate(DateTime.now()),
          'qdii': '',
          'tabSubtype': tp,
          'pi': page,
          'pn': size,
          'dx': '1',
        },
        options: Options(
          headers: {
            'Referer': 'https://fund.eastmoney.com/data/fundranking.html',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      return _parseRankResponse(response.data as String);
    } on DioException catch (e) {
      throw _handleDioError(e, '获取指数基金列表');
    } catch (e) {
      throw Exception('获取指数基金列表失败: $e');
    }
  }
  
  /// 获取热门指数基金
  Future<List<Fund>> getHotIndexFunds({int size = 10}) async {
    return getIndexFunds(type: 'all', sort: 'rzdf', page: 1, size: size);
  }
  
  /// 获取宽基指数基金
  Future<List<Fund>> getBroadIndexFunds({int page = 1, int size = 20}) async {
    return getIndexFunds(type: 'broad', sort: 'rzdf', page: page, size: size);
  }
  
  /// 获取行业指数基金
  Future<List<Fund>> getSectorIndexFunds({int page = 1, int size = 20}) async {
    return getIndexFunds(type: 'sector', sort: 'rzdf', page: page, size: size);
  }
  
  /// 获取基金实时数据（内部方法）
  Future<Fund?> _getFundRealTimeData(String fundCode) async {
    try {
      final response = await _dio.get(
        '$_fundDetailUrl/$fundCode.js',
        options: Options(
          headers: {
            'Referer': 'https://fund.eastmoney.com/',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      return _parseFundRealTimeData(fundCode, response.data as String);
    } catch (e) {
      print('获取基金实时数据失败: $e');
      return null;
    }
  }
  
  /// 获取基金详细信息（内部方法）
  Future<Map<String, dynamic>?> _getFundInfo(String fundCode) async {
    try {
      final response = await _dio.get(
        '$_fundInfoUrl/$fundCode.js',
        options: Options(
          headers: {
            'Referer': 'https://fund.eastmoney.com/',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      return _parseFundInfoData(response.data as String);
    } catch (e) {
      print('获取基金详细信息失败: $e');
      return null;
    }
  }
  
  // ==================== 解析方法 ====================
  
  /// 解析搜索响应
  List<Fund> _parseSearchResponse(String data) {
    if (data.isEmpty) return [];
    
    try {
      // 解析JSONP响应: callback({"Datas":[...],"AllCount":...})
      final jsonStart = data.indexOf('(');
      final jsonEnd = data.lastIndexOf(')');
      if (jsonStart == -1 || jsonEnd == -1) return [];
      
      final jsonStr = data.substring(jsonStart + 1, jsonEnd);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      final datas = json['Datas'] as List? ?? [];
      final now = DateTime.now();
      
      return datas.map((item) {
        final map = item as Map<String, dynamic>;
        return Fund(
          code: map['CODE']?.toString() ?? map['FCODE']?.toString() ?? '',
          name: map['NAME']?.toString() ?? map['SHORTNAME']?.toString() ?? '',
          type: _getFundType(map['FTYPE']?.toString() ?? ''),
          currentPrice: _parseDouble(map['NAV']) ?? 0,
          dayChange: _parseDouble(map['NAVCHGRT']) ?? 0,
          dayChangeRate: _parseDouble(map['NAVCHGRT']) ?? 0,
          updatedAt: now,
          scale: _parseDouble(map['FSCALE']),
          fundCompany: map['JJGSNAME']?.toString(),
          return1y: _parseDouble(map['RZDF']),
          return3y: _parseDouble(map['THREEYZF']),
        );
      }).where((f) => f.code.isNotEmpty && f.name.isNotEmpty).toList();
    } catch (e) {
      print('解析搜索响应失败: $e');
      return [];
    }
  }
  
  /// 解析基金实时数据
  Fund? _parseFundRealTimeData(String fundCode, String data) {
    if (data.isEmpty || data.contains('var=')) return null;
    
    try {
      // 解析: var jsonszjj = {"fundcode":"000001","name":"华夏成长",...}
      final jsonStart = data.indexOf('{');
      final jsonEnd = data.lastIndexOf('}');
      if (jsonStart == -1 || jsonEnd == -1) return null;
      
      final jsonStr = data.substring(jsonStart, jsonEnd + 1);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      
      return Fund(
        code: json['fundcode']?.toString() ?? fundCode,
        name: json['name']?.toString() ?? '',
        type: _getFundType(json['fundtype']?.toString() ?? ''),
        currentPrice: _parseDouble(json['gsz']) ?? _parseDouble(json['dwjz']) ?? 0,
        dayChange: _parseDouble(json['gszzl']) ?? 0,
        dayChangeRate: _parseDouble(json['gszzl']) ?? 0,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('解析基金实时数据失败: $e');
      return null;
    }
  }
  
  /// 解析净值历史响应
  List<FundNetValue> _parseNetValueResponse(String fundCode, dynamic data) {
    if (data is! Map) return [];
    
    try {
      final items = data['Data']?['LSJZList'] as List? ?? [];
      
      return items.map((item) {
        final map = item as Map<String, dynamic>;
        return FundNetValue(
          fundCode: fundCode,
          date: _parseDate(map['FSRQ']?.toString()) ?? DateTime.now(),
          netValue: _parseDouble(map['DWJZ']) ?? 0,
          cumulativeValue: _parseDouble(map['LJJZ']) ?? 0,
          dayChangeRate: _parseDouble(map['JZZZL']),
        );
      }).toList();
    } catch (e) {
      print('解析净值历史失败: $e');
      return [];
    }
  }
  
  /// 解析排行响应
  List<Fund> _parseRankResponse(String data) {
    if (data.isEmpty) return [];
    
    try {
      // 解析: var rankData = {datas:["代码,名称,...",...]}
      final datasMatch = RegExp(r'datas:\s*\[(.*?)\]').firstMatch(data);
      if (datasMatch == null) return [];
      
      final items = RegExp(r'"([^"]+)"')
        .allMatches(datasMatch.group(1)!)
        .map((m) => m.group(1)!)
        .toList();
      
      final now = DateTime.now();
      
      return items.map((item) {
        final fields = item.split(',');
        if (fields.length < 10) return null;
        
        return Fund(
          code: fields[0].trim(),
          name: fields[1].trim(),
          type: _getFundTypeFromCode(fields[0].trim()),
          currentPrice: _parseDouble(fields[3]) ?? 0,
          dayChangeRate: _parseDouble(fields[4]) ?? 0,
          dayChange: (_parseDouble(fields[3]) ?? 0) * (_parseDouble(fields[4]) ?? 0) / 100,
          updatedAt: now,
          scale: _parseDouble(fields[19]),
          return1y: _parseDouble(fields[10]),
          return3y: _parseDouble(fields[12]),
          return5y: _parseDouble(fields[14]),
          return1y: _parseDouble(fields[10]),
        );
      }).whereType<Fund>().where((f) => f.code.isNotEmpty).toList();
    } catch (e) {
      print('解析排行数据失败: $e');
      return [];
    }
  }
  
  /// 解析基金信息数据
  Map<String, dynamic>? _parseFundInfoData(String data) {
    if (data.isEmpty) return null;
    
    try {
      final result = <String, dynamic>{};
      
      // 解析基金规模
      final scaleMatch = RegExp(r'fund_jjgm\s*=\s*"([\d.]+)"').firstMatch(data);
      if (scaleMatch != null) {
        result['scale'] = double.tryParse(scaleMatch.group(1)!);
      }
      
      // 解析基金公司
      final companyMatch = RegExp(r'fund_jjgs\s*=\s*"([^"]+)"').firstMatch(data);
      if (companyMatch != null) {
        result['fundCompany'] = companyMatch.group(1);
      }
      
      // 解析成立日期
      final establishMatch = RegExp(r'fund_clrq\s*=\s*"([^"]+)"').firstMatch(data);
      if (establishMatch != null) {
        result['establishDate'] = _parseDate(establishMatch.group(1)!);
      }
      
      // 解析跟踪指数
      final indexMatch = RegExp(r'fund_gzindex\s*=\s*"([^"]+)"').firstMatch(data);
      if (indexMatch != null) {
        result['trackingIndex'] = indexMatch.group(1);
      }
      
      // 解析管理费率
      final mgmtFeeMatch = RegExp(r'fund_glf\s*=\s*"([\d.]+)%"').firstMatch(data);
      if (mgmtFeeMatch != null) {
        result['managementFee'] = (double.tryParse(mgmtFeeMatch.group(1)!) ?? 0) / 100;
      }
      
      // 解析托管费率
      final custodyFeeMatch = RegExp(r'fund_tgf\s*=\s*"([\d.]+)%"').firstMatch(data);
      if (custodyFeeMatch != null) {
        result['custodyFee'] = (double.tryParse(custodyFeeMatch.group(1)!) ?? 0) / 100;
      }
      
      return result.isNotEmpty ? result : null;
    } catch (e) {
      print('解析基金信息失败: $e');
      return null;
    }
  }
  
  // ==================== 辅助方法 ====================
  
  /// 处理Dio错误
  Exception _handleDioError(DioException e, String operation) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('$operation失败: 网络超时，请检查网络连接');
      case DioExceptionType.connectionError:
        return Exception('$operation失败: 网络连接错误');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          return Exception('$operation失败: 未找到相关数据');
        } else if (statusCode != null && statusCode >= 500) {
          return Exception('$operation失败: 服务器错误($statusCode)');
        }
        return Exception('$operation失败: HTTP $statusCode');
      case DioExceptionType.cancel:
        return Exception('$operation已取消');
      default:
        return Exception('$operation失败: ${e.message}');
    }
  }
  
  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  /// 解析日期
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // 支持多种格式
      if (dateStr.contains('-')) {
        return DateTime.parse(dateStr);
      } else if (dateStr.length == 8) {
        return DateTime.parse('${dateStr.substring(0, 4)}-${dateStr.substring(4, 6)}-${dateStr.substring(6, 8)}');
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// 解析double
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
  
  /// 获取基金类型名称
  String _getFundType(String code) {
    final typeMap = {
      'ETF': 'ETF基金',
      'LOF': 'LOF基金',
      'QDII': 'QDII基金',
      '股票型': '股票型基金',
      '混合型': '混合型基金',
      '债券型': '债券型基金',
      '指数型': '指数型基金',
      '货币型': '货币基金',
    };
    return typeMap[code] ?? code;
  }
  
  /// 根据基金代码推断类型
  String _getFundTypeFromCode(String code) {
    if (code.startsWith('51') || code.startsWith('159')) {
      return 'ETF基金';
    } else if (code.startsWith('16') && code.endsWith('11')) {
      return 'LOF基金';
    } else if (code.startsWith('00') || code.startsWith('01')) {
      return '指数型基金';
    }
    return '指数型基金';
  }
}
