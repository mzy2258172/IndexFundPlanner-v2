# IndexFundPlanner 构建指南

## 环境要求
- Flutter SDK 3.24+
- Android SDK (API 21+)
- Java 17

## 构建步骤

```bash
# 1. 安装依赖
flutter pub get

# 2. 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 3. 构建 APK
flutter build apk --release

# 4. APK 输出位置
# build/app/outputs/flutter-apk/app-release.apk
```

## 快速测试 (Web)
```bash
flutter run -d chrome
```

## 测试账号
- 验证码: 123456 或 000000
