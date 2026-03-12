import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hive Box Names
class HiveBoxes {
  static const String portfolio = 'portfolio';
  static const String funds = 'funds';
  static const String settings = 'settings';
}

/// Hive 服务 Provider
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

class HiveService {
  Future<Box<T>> getBox<T>(String name) async {
    if (!Hive.isBoxOpen(name)) {
      return await Hive.openBox<T>(name);
    }
    return Hive.box<T>(name);
  }
  
  Future<void> put<T>(String boxName, String key, T value) async {
    final box = await getBox<T>(boxName);
    await box.put(key, value);
  }
  
  T? get<T>(String boxName, String key) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box<T>(boxName);
    return box.get(key);
  }
  
  Future<void> delete<T>(String boxName, String key) async {
    final box = await getBox<T>(boxName);
    await box.delete(key);
  }
  
  Future<void> clear(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }
}
