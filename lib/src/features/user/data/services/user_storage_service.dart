import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/entities/user.dart';

/// 用户存储服务 - 处理用户数据的持久化
class UserStorageService {
  static const String _userBoxName = 'user_storage';
  static const String _currentUserKey = 'current_user';
  static const String _assessmentHistoryKey = 'assessment_history';
  static const String _userSettingsKey = 'user_settings';
  
  Box<String>? _box;
  
  /// 获取或初始化 Hive Box
  Future<Box<String>> _getBox() async {
    _box ??= await Hive.openBox<String>(_userBoxName);
    return _box!;
  }
  
  /// 保存当前用户
  Future<void> saveCurrentUser(User user) async {
    final box = await _getBox();
    await box.put(_currentUserKey, jsonEncode(user.toJson()));
  }
  
  /// 获取当前用户
  Future<User?> getCurrentUser() async {
    final box = await _getBox();
    final jsonStr = box.get(_currentUserKey);
    if (jsonStr == null) return null;
    
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (e) {
      // 数据损坏时返回 null
      return null;
    }
  }
  
  /// 删除当前用户（退出登录）
  Future<void> deleteCurrentUser() async {
    final box = await _getBox();
    await box.delete(_currentUserKey);
  }
  
  /// 检查用户是否已登录
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }
  
  /// 保存风险测评结果
  Future<void> saveRiskAssessment(RiskAssessment assessment) async {
    final box = await _getBox();
    
    // 保存到历史记录
    final historyJson = box.get(_assessmentHistoryKey);
    List<Map<String, dynamic>> history = [];
    
    if (historyJson != null) {
      try {
        history = (jsonDecode(historyJson) as List)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      } catch (_) {}
    }
    
    // 添加新记录到开头
    history.insert(0, {
      'id': assessment.id,
      'userId': assessment.userId,
      'answers': assessment.answers.map((a) => {
        'questionIndex': a.questionIndex,
        'answerIndex': a.answerIndex,
        'score': a.score,
      }).toList(),
      'totalScore': assessment.totalScore,
      'riskLevel': assessment.riskLevel.index,
      'assessedAt': assessment.assessedAt.toIso8601String(),
    });
    
    // 只保留最近5条记录
    if (history.length > 5) {
      history = history.sublist(0, 5);
    }
    
    await box.put(_assessmentHistoryKey, jsonEncode(history));
    
    // 更新用户的风险等级
    final user = await getCurrentUser();
    if (user != null) {
      await saveCurrentUser(user.copyWith(
        riskLevel: assessment.riskLevel,
        riskAssessmentDate: assessment.assessedAt,
      ));
    }
  }
  
  /// 获取最近的风险测评
  Future<RiskAssessment?> getLatestRiskAssessment() async {
    final box = await _getBox();
    final historyJson = box.get(_assessmentHistoryKey);
    
    if (historyJson == null) return null;
    
    try {
      final history = jsonDecode(historyJson) as List;
      if (history.isEmpty) return null;
      
      final latest = history.first as Map<String, dynamic>;
      return RiskAssessment(
        id: latest['id'] as String,
        userId: latest['userId'] as String,
        answers: (latest['answers'] as List).map((a) {
          final map = a as Map<String, dynamic>;
          return RiskAnswer(
            questionIndex: map['questionIndex'] as int,
            answerIndex: map['answerIndex'] as int,
            score: map['score'] as int,
          );
        }).toList(),
        totalScore: latest['totalScore'] as int,
        riskLevel: RiskLevel.values[latest['riskLevel'] as int],
        assessedAt: DateTime.parse(latest['assessedAt'] as String),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// 获取风险测评历史
  Future<List<RiskAssessment>> getRiskAssessmentHistory() async {
    final box = await _getBox();
    final historyJson = box.get(_assessmentHistoryKey);
    
    if (historyJson == null) return [];
    
    try {
      final history = jsonDecode(historyJson) as List;
      return history.map((item) {
        final map = item as Map<String, dynamic>;
        return RiskAssessment(
          id: map['id'] as String,
          userId: map['userId'] as String,
          answers: (map['answers'] as List).map((a) {
            final m = a as Map<String, dynamic>;
            return RiskAnswer(
              questionIndex: m['questionIndex'] as int,
              answerIndex: m['answerIndex'] as int,
              score: m['score'] as int,
            );
          }).toList(),
          totalScore: map['totalScore'] as int,
          riskLevel: RiskLevel.values[map['riskLevel'] as int],
          assessedAt: DateTime.parse(map['assessedAt'] as String),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 保存用户设置
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final box = await _getBox();
    await box.put(_userSettingsKey, jsonEncode(settings));
  }
  
  /// 获取用户设置
  Future<Map<String, dynamic>> getUserSettings() async {
    final box = await _getBox();
    final jsonStr = box.get(_userSettingsKey);
    
    if (jsonStr == null) {
      return _defaultSettings();
    }
    
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (e) {
      return _defaultSettings();
    }
  }
  
  Map<String, dynamic> _defaultSettings() => {
    'theme': 'system',
    'notifications': true,
    'autoSync': true,
    'language': 'zh_CN',
  };
  
  /// 清除所有用户数据
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
  
  /// 导出用户数据（用于备份）
  Future<Map<String, dynamic>> exportUserData() async {
    final box = await _getBox();
    final user = await getCurrentUser();
    final history = await getRiskAssessmentHistory();
    final settings = await getUserSettings();
    
    return {
      'user': user?.toJson(),
      'assessmentHistory': history.map((a) => {
        return {
          'id': a.id,
          'userId': a.userId,
          'answers': a.answers.map((ans) => {
            return {
              'questionIndex': ans.questionIndex,
              'answerIndex': ans.answerIndex,
              'score': ans.score,
            };
          }).toList(),
          'totalScore': a.totalScore,
          'riskLevel': a.riskLevel.index,
          'assessedAt': a.assessedAt.toIso8601String(),
        };
      }).toList(),
      'settings': settings,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }
}
