# Sprint 3: 投资计划模块实现报告

## 完成时间
2026-03-12

## 新增代码文件

### 1. 组合推荐算法

#### fund_scoring.dart (557 行)
**位置**: `lib/src/features/plan/domain/services/fund_scoring.dart`

**功能说明**:
- `FundScoringModel`: 基金评分数据模型，包含收益、风险、跟踪误差、费率、规模等维度
- `FundScoreResult`: 基金评分结果，0-100分制，含星级评级
- `FundScoringService`: 基金评分服务，提供单基金评分和批量评分功能

**评分维度权重**:
| 维度 | 权重 | 满分 |
|------|------|------|
| 收益能力 | 40% | 40分 |
| 风险控制 | 30% | 30分 |
| 跟踪效果 | 15% | 15分 |
| 费率优势 | 10% | 10分 |
| 规模流动性 | 5% | 5分 |

**内置基金数据库**: 包含 16 只主流指数基金数据

---

#### portfolio_recommendation.dart (750 行)
**位置**: `lib/src/features/plan/domain/services/portfolio_recommendation.dart`

**功能说明**:
- `PortfolioRecommendationEngine`: 组合推荐引擎
  - 根据风险等级生成资产配置框架
  - 生成三档方案（稳健/均衡/进取）
  - 建议月投入额计算
  - 可行性评分计算
  - 组合优化算法
  - 组合对比功能
  - 调仓建议生成

- `PortfolioBacktestService`: 组合回测服务
  - 历史回测计算
  - 净值曲线生成
  - 收益指标计算（总收益、年化收益、最大回撤、夏普比率、波动率）

**资产配置框架**:
| 风险等级 | 货币 | 债券 | 宽基 | 行业 |
|---------|------|------|------|------|
| C1 保守型 | 40% | 50% | 10% | 0% |
| C2 稳健型 | 20% | 40% | 30% | 10% |
| C3 平衡型 | 10% | 30% | 40% | 20% |
| C4 进取型 | 5% | 15% | 50% | 30% |
| C5 激进型 | 0% | 10% | 50% | 40% |

---

### 2. 定投计划管理

#### sip_service.dart (473 行)
**位置**: `lib/src/features/plan/domain/services/sip_service.dart`

**功能说明**:
- `SipCalculationService`: 定投计算服务
  - 下次执行日期计算（支持每周/每两周/每月）
  - 定投复利终值计算
  - 反推月投入额计算
  - 均线策略调整系数计算
  - 价值平均策略投入额计算
  - 定投收益计算

- `SipPlanService`: 定投计划管理服务
  - 创建定投计划
  - 暂停/恢复/终止定投
  - 执行定投（支持三种策略）

- `SipReminderService`: 定投提醒服务
  - 检查是否需要提醒
  - 获取提醒消息

**支持的定投策略**:
1. **普通定投**: 每期固定金额
2. **均线策略**: 低估多投，高估少投（调整系数 0.5-2.0）
3. **价值平均策略**: 保持市值稳定增长

---

#### plan_records.dart (272 行)
**位置**: `lib/src/features/plan/domain/entities/plan_records.dart`

**功能说明**:
- `SipExecution`: 定投执行记录实体
- `RebalanceRecord`: 调仓记录实体
- `RebalanceTransaction`: 调仓交易明细
- `PlanDetailView`: 投资计划详细视图
- `PlanProgress`: 计划进度指标
- `PlanRiskMetrics`: 计划风险指标

---

### 3. 投资计划存储

#### plan_service.dart (378 行)
**位置**: `lib/src/features/plan/domain/services/plan_service.dart`

**功能说明**:
- `InvestmentPlanService`: 投资计划服务
  - 创建投资计划
  - 为计划创建投资组合
  - 为计划创建定投计划
  - 计算计划进度
  - 计算计划风险指标
  - 生成计划详细视图
  - 检查是否需要调仓
  - 暂停/恢复/终止计划
  - 计算计划统计信息

- `PlanStatistics`: 计划统计信息

---

#### plan_records_storage.dart (281 行)
**位置**: `lib/src/features/plan/data/storage/plan_records_storage.dart`

**功能说明**:
- `SipExecutionStorage`: 定投执行记录存储
  - 保存/查询执行记录
  - 按日期范围查询
  - 获取最近执行记录
  - 更新执行状态
  - 获取执行统计

- `RebalanceRecordStorage`: 调仓记录存储
  - 保存/查询调仓记录
  - 按计划/组合查询

---

#### enhanced_plan_repository_impl.dart (272 行)
**位置**: `lib/src/features/plan/data/repositories/enhanced_plan_repository_impl.dart`

**功能说明**:
- `EnhancedPlanRepositoryImpl`: 增强的计划存储实现
  - 继承原有 PlanRepository 接口
  - 获取计划详细视图
  - 获取活跃/已完成计划
  - 按目标类型筛选
  - 获取需要提醒的计划
  - 保存定投执行记录
  - 保存调仓记录
  - 导入/导出计划数据

---

### 4. 测试文件

#### plan_module_test.dart (311 行)
**位置**: `test/plan_module_test.dart`

**测试覆盖**:
- 基金评分模型测试
- 批量评分测试
- 评分维度测试
- 资产配置测试
- 三档方案生成测试
- 建议月投入额计算测试
- 可行性评分测试
- 定投计算服务测试
- 投资计划服务测试
- 组合回测测试

---

## 代码统计

| 文件 | 行数 |
|------|------|
| fund_scoring.dart | 557 |
| sip_service.dart | 473 |
| portfolio_recommendation.dart | 750 |
| plan_records.dart | 272 |
| plan_service.dart | 378 |
| plan_records_storage.dart | 281 |
| enhanced_plan_repository_impl.dart | 272 |
| plan_module_test.dart | 311 |
| **总计** | **3294 行** |

---

## 功能验收

### ✅ 根据风险等级生成投资计划
- 实现了 `PortfolioRecommendationEngine.generateRecommendedPortfolios()`
- 支持生成稳健/均衡/进取三档方案
- 根据风险等级自动配置资产比例

### ✅ 计划可以保存和读取
- 实现了 `EnhancedPlanRepositoryImpl`
- 支持 Hive 本地存储
- 支持计划详情查询、筛选、导入导出

### ✅ 定投计算逻辑正确
- 实现了三种定投策略（普通/均线/价值平均）
- 定投复利终值计算
- 下次执行日期计算
- 定投提醒逻辑

---

## 使用示例

### 创建投资计划
```dart
// 1. 创建计划
final plan = InvestmentPlanService.createPlan(
  userId: 'user_001',
  name: '教育金计划',
  goalType: PlanGoalType.education,
  targetAmount: 500000,
  initialCapital: 50000,
  targetDate: DateTime.now().add(Duration(days: 365 * 5)),
);

// 2. 创建投资组合
final portfolio = InvestmentPlanService.createPortfolioForPlan(
  plan: plan,
  riskLevel: 3, // 平衡型
);

// 3. 创建定投计划
final sipPlan = InvestmentPlanService.createSipForPlan(
  plan: plan,
  frequency: 'monthly',
  investmentDay: 15,
  strategy: 'ma', // 均线策略
);

// 4. 完成计划
final completePlan = InvestmentPlanService.completePlan(
  plan: plan,
  portfolio: portfolio,
  sipPlan: sipPlan,
);
```

### 查询计划进度
```dart
final progress = InvestmentPlanService.calculateProgress(plan);
print('进度: ${progress.progressPercent}%');
print('剩余天数: ${progress.remainingDays}');
print('状态: ${progress.progressStatus}');
```

### 执行定投
```dart
final result = SipPlanService.executeSip(
  plan: sipPlan,
  currentNav: 4.5,
  maValue: 4.8, // 均线策略需要的均线值
);
print('实际投入: ${result.amount}');
print('调整系数: ${result.adjustment}');
```

---

## 依赖关系

```
plan/
├── domain/
│   ├── entities/
│   │   ├── plan.dart (原有)
│   │   └── plan_records.dart (新增)
│   ├── repositories/
│   │   └── plan_repository.dart (原有)
│   └── services/
│       ├── portfolio_recommendation.dart (完善)
│       ├── fund_scoring.dart (新增)
│       ├── sip_service.dart (新增)
│       └── plan_service.dart (新增)
└── data/
    ├── repositories/
    │   ├── plan_repository_impl.dart (原有)
    │   └── enhanced_plan_repository_impl.dart (新增)
    └── storage/
        └── plan_records_storage.dart (新增)
```

---

## 后续建议

1. **集成测试**: 添加与 UI 层的集成测试
2. **数据同步**: 考虑云端数据同步功能
3. **通知服务**: 集成系统通知服务实现定投提醒
4. **性能优化**: 大数据量下的查询优化
5. **错误处理**: 增强异常处理和日志记录
