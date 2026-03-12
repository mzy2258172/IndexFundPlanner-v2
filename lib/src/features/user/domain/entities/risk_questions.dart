import '../entities/user.dart';

/// 风险测评问卷题目（10题）
const List<RiskQuestion> riskQuestions = [
  // 年龄 (权重15%)
  RiskQuestion(
    index: 0,
    question: '您的年龄是？',
    category: '年龄',
    weight: 15,
    options: [
      RiskOption(index: 0, text: '30岁以下', score: 15),
      RiskOption(index: 1, text: '30-40岁', score: 12),
      RiskOption(index: 2, text: '40-50岁', score: 8),
      RiskOption(index: 3, text: '50-60岁', score: 4),
      RiskOption(index: 4, text: '60岁以上', score: 0),
    ],
  ),
  
  // 投资经验 (权重20%)
  RiskQuestion(
    index: 1,
    question: '您的投资经验年限？',
    category: '投资经验',
    weight: 10,
    options: [
      RiskOption(index: 0, text: '无投资经验', score: 0),
      RiskOption(index: 1, text: '1年以下', score: 3),
      RiskOption(index: 2, text: '1-3年', score: 6),
      RiskOption(index: 3, text: '3-5年', score: 8),
      RiskOption(index: 4, text: '5年以上', score: 10),
    ],
  ),
  
  RiskQuestion(
    index: 2,
    question: '您是否投资过以下产品？（可多选经历最丰富的）',
    category: '投资经验',
    weight: 10,
    options: [
      RiskOption(index: 0, text: '仅银行存款/货币基金', score: 0),
      RiskOption(index: 1, text: '银行理财/债券基金', score: 4),
      RiskOption(index: 2, text: '混合基金/指数基金', score: 7),
      RiskOption(index: 3, text: '股票/股票基金', score: 10),
      RiskOption(index: 4, text: '期货/期权等衍生品', score: 12),
    ],
  ),
  
  // 收入水平 (权重15%)
  RiskQuestion(
    index: 3,
    question: '您的家庭年收入大约是？',
    category: '收入水平',
    weight: 15,
    options: [
      RiskOption(index: 0, text: '10万元以下', score: 2),
      RiskOption(index: 1, text: '10-30万元', score: 6),
      RiskOption(index: 2, text: '30-50万元', score: 10),
      RiskOption(index: 3, text: '50-100万元', score: 13),
      RiskOption(index: 4, text: '100万元以上', score: 15),
    ],
  ),
  
  // 资产状况 (权重15%)
  RiskQuestion(
    index: 4,
    question: '您可用于投资的资产（不含房产）大约是？',
    category: '资产状况',
    weight: 8,
    options: [
      RiskOption(index: 0, text: '10万元以下', score: 1),
      RiskOption(index: 1, text: '10-50万元', score: 4),
      RiskOption(index: 2, text: '50-100万元', score: 6),
      RiskOption(index: 3, text: '100-300万元', score: 8),
      RiskOption(index: 4, text: '300万元以上', score: 10),
    ],
  ),
  
  RiskQuestion(
    index: 5,
    question: '您投资资金占家庭总资产的比例是？',
    category: '资产状况',
    weight: 7,
    options: [
      RiskOption(index: 0, text: '10%以下', score: 7),
      RiskOption(index: 1, text: '10%-30%', score: 5),
      RiskOption(index: 2, text: '30%-50%', score: 3),
      RiskOption(index: 3, text: '50%-70%', score: 1),
      RiskOption(index: 4, text: '70%以上', score: 0),
    ],
  ),
  
  // 投资目标 (权重15%)
  RiskQuestion(
    index: 6,
    question: '您的主要投资目标是？',
    category: '投资目标',
    weight: 8,
    options: [
      RiskOption(index: 0, text: '保本，不希望有任何损失', score: 0),
      RiskOption(index: 1, text: '稳健增值，可接受小幅波动', score: 4),
      RiskOption(index: 2, text: '资产增长，可接受中等波动', score: 7),
      RiskOption(index: 3, text: '高收益，可接受较大波动', score: 10),
    ],
  ),
  
  RiskQuestion(
    index: 7,
    question: '您预期的投资期限是？',
    category: '投资目标',
    weight: 7,
    options: [
      RiskOption(index: 0, text: '1年以内', score: 0),
      RiskOption(index: 1, text: '1-3年', score: 4),
      RiskOption(index: 2, text: '3-5年', score: 6),
      RiskOption(index: 3, text: '5年以上', score: 8),
    ],
  ),
  
  // 风险态度 (权重20%)
  RiskQuestion(
    index: 8,
    question: '如果您的投资下跌20%，您会怎么做？',
    category: '风险态度',
    weight: 10,
    options: [
      RiskOption(index: 0, text: '全部卖出，无法承受损失', score: 0),
      RiskOption(index: 1, text: '卖出部分，减少损失', score: 3),
      RiskOption(index: 2, text: '持有不动，等待恢复', score: 6),
      RiskOption(index: 3, text: '逢低加仓，摊低成本', score: 10),
    ],
  ),
  
  RiskQuestion(
    index: 9,
    question: '以下哪种收益与风险组合最符合您的期望？',
    category: '风险态度',
    weight: 10,
    options: [
      RiskOption(index: 0, text: '年化收益2-4%，最大回撤<5%', score: 0),
      RiskOption(index: 1, text: '年化收益4-8%，最大回撤<15%', score: 5),
      RiskOption(index: 2, text: '年化收益8-15%，最大回撤<30%', score: 8),
      RiskOption(index: 3, text: '年化收益>15%，最大回撤可能>30%', score: 12),
    ],
  ),
];
