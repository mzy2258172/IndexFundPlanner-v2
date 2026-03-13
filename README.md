# IndexFundPlanner

指数基金投资规划助手 - 帮助您管理指数基金投资组合

## 项目概述

本项目是一个基于 Flutter 开发的指数基金投资规划应用，采用 Clean Architecture 架构模式，支持投资组合管理、基金查询、收益分析、定投计划等功能。

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **Riverpod**: 状态管理
- **Dio**: 网络请求
- **Hive**: 本地存储
- **fl_chart**: 图表展示
- **go_router**: 路由管理

## 项目结构

```
lib/
├── main.dart                          # 应用入口
└── src/
    ├── core/                          # 核心功能
    │   ├── constants/                 # 常量定义
    │   ├── errors/                    # 错误处理
    │   ├── network/                   # 网络配置
    │   ├── providers/                 # 认证守卫
    │   ├── router/                    # 路由配置
    │   └── storage/                   # 存储服务
    │
    ├── features/                      # 功能模块
    │   ├── user/                      # 用户模块
    │   │   ├── domain/entities/       # 用户实体、风险等级
    │   │   ├── data/repositories/     # 用户仓储实现
    │   │   └── presentation/          # 登录页、风险测评
    │   │
    │   ├── portfolio/                 # 投资组合模块
    │   │   ├── domain/entities/       # 组合实体、持仓项
    │   │   ├── data/repositories/     # 组合仓储实现
    │   │   └── presentation/          # 组合列表、详情、添加持仓
    │   │
    │   ├── fund/                      # 基金模块
    │   │   ├── domain/entities/       # 基金实体、净值历史
    │   │   ├── data/services/         # 东财 API 服务
    │   │   └── presentation/          # 基金列表、详情页
    │   │
    │   ├── plan/                      # 投资计划模块
    │   │   ├── domain/                # 计划实体、组合推荐算法
    │   │   ├── data/                  # 计划仓储实现
    │   │   └── presentation/          # 创建计划、计划详情
    │   │
    │   └── analytics/                 # 分析模块
    │       ├── domain/entities/       # 分析报告实体
    │       └── presentation/          # 分析页面、Provider
    │
    └── shared/                        # 共享组件
        ├── pages/                     # 首页、设置页
        └── widgets/                   # 通用组件
```

## 架构说明

### Clean Architecture 分层

1. **Domain Layer (领域层)**
   - `entities/`: 业务实体
   - `repositories/`: 仓储接口

2. **Data Layer (数据层)**
   - `services/`: 外部 API 服务
   - `repositories/`: 仓储实现

3. **Presentation Layer (表现层)**
   - `pages/`: 页面
   - `providers/`: 状态管理

## 快速开始

### 环境要求

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run -d chrome     # Web
flutter run -d macos      # macOS
flutter run -d android    # Android
```

### 测试账号

- 手机号: 任意 11 位
- 验证码: `123456` 或 `000000`

## 核心功能

### ✅ 已完成

- [x] 用户登录/注册
- [x] 风险测评问卷 (10 题)
- [x] 投资组合管理
  - [x] 组合列表展示
  - [x] 持仓录入
  - [x] 收益计算
  - [x] 持仓分布可视化
- [x] 基金数据
  - [x] 基金列表（分类、搜索、筛选）
  - [x] 基金详情
  - [x] 净值走势图
- [x] 投资计划
  - [x] 创建计划（向导式）
  - [x] 组合推荐算法
  - [x] 计划详情
- [x] 投资分析
  - [x] 收益概览
  - [x] 风险指标

### 🚧 开发中

- [ ] 定投计划执行
- [ ] 云端数据同步
- [ ] 深色模式

## 页面路由

| 路由 | 页面 | 说明 |
|------|------|------|
| `/login` | LoginPage | 登录/注册 |
| `/risk-assessment` | RiskAssessmentPage | 风险测评 |
| `/home` | HomePage | 首页 |
| `/portfolio` | PortfolioPage | 投资组合列表 |
| `/portfolio/:id` | PortfolioDetailPage | 组合详情 |
| `/add-holding` | AddHoldingPage | 添加持仓 |
| `/funds` | FundListPage | 基金列表 |
| `/fund/:code` | FundDetailPage | 基金详情 |
| `/analytics` | AnalyticsPage | 投资分析 |
| `/settings` | SettingsPage | 设置 |
| `/create-plan` | CreatePlanPage | 创建计划 |
| `/plan/:id` | PlanDetailPage | 计划详情 |

## 技术亮点

1. **Clean Architecture**: 清晰的分层架构，便于维护和测试
2. **Riverpod 状态管理**: 类型安全、响应式的状态管理
3. **Sealed Class 状态**: 替代 freezed，简化构建流程
4. **Hive 本地存储**: 轻量级 NoSQL 数据库，无需原生依赖
5. **fl_chart 图表**: 纯 Dart 实现的图表库，支持饼图、折线图
6. **go_router 路由**: 声明式路由，支持深链接

## 开发计划

### P1 - 功能完善
- [ ] 定投计划定时执行
- [ ] 扣款提醒通知
- [ ] 调仓建议

### P2 - 用户体验
- [ ] 云端数据同步
- [ ] 深色模式
- [ ] 性能优化

### P3 - 高级功能
- [ ] 智能推荐
- [ ] 投资教育内容
- [ ] 社区功能

## 注意事项

1. **天天基金 API**: 当前使用模拟数据，生产环境需接入真实 API
2. **用户认证**: 需要接入真实短信服务
3. **交易功能**: 需要基金销售牌照或与持牌机构合作

## License

MIT

---
*Last build attempt: 2025-03-13*
