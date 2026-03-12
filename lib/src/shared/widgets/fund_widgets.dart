import 'package:flutter/material.dart';

/// 收益显示组件
class ReturnDisplay extends StatelessWidget {
  final double returnRate;
  final double? returnAmount;
  final bool showPercentage;
  final bool showAmount;
  
  const ReturnDisplay({
    super.key,
    required this.returnRate,
    this.returnAmount,
    this.showPercentage = true,
    this.showAmount = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final isPositive = returnRate >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final prefix = isPositive ? '+' : '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showPercentage)
          Text(
            '$prefix${(returnRate * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (showAmount && returnAmount != null)
          Text(
            '$prefix¥${returnAmount!.abs().toStringAsFixed(2)}',
            style: TextStyle(
              color: color,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}

/// 净值显示组件
class NetValueDisplay extends StatelessWidget {
  final double netValue;
  final double? dayChange;
  final double? dayChangeRate;
  
  const NetValueDisplay({
    super.key,
    required this.netValue,
    this.dayChange,
    this.dayChangeRate,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          netValue.toStringAsFixed(4),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (dayChangeRate != null)
          Text(
            '${dayChangeRate! >= 0 ? '+' : ''}${(dayChangeRate! * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: dayChangeRate! >= 0 ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
      ],
    );
  }
}
