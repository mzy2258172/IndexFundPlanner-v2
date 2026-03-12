import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/risk_questions.dart';
import '../providers/user_provider.dart';

class RiskAssessmentPage extends ConsumerStatefulWidget {
  const RiskAssessmentPage({super.key});
  
  @override
  ConsumerState<RiskAssessmentPage> createState() => _RiskAssessmentPageState();
}

class _RiskAssessmentPageState extends ConsumerState<RiskAssessmentPage> {
  int _currentIndex = 0;
  final Map<int, int> _answers = {}; // questionIndex -> answerIndex
  bool _loading = false;
  
  late PageController _pageController;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  int get _totalScore {
    int score = 0;
    _answers.forEach((questionIndex, answerIndex) {
      final question = riskQuestions[questionIndex];
      final option = question.options[answerIndex];
      score += option.score;
    });
    return score;
  }
  
  double get _progress => (_currentIndex + 1) / riskQuestions.length;
  
  void _selectAnswer(int answerIndex) {
    setState(() {
      _answers[_currentIndex] = answerIndex;
    });
  }
  
  void _nextQuestion() {
    if (_currentIndex < riskQuestions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex++);
    } else {
      _submitAssessment();
    }
  }
  
  void _prevQuestion() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentIndex--);
    }
  }
  
  Future<void> _submitAssessment() async {
    setState(() => _loading = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;
      
      final totalScore = _totalScore;
      final riskLevel = RiskAssessment.calculateRiskLevel(totalScore);
      
      final assessment = RiskAssessment(
        id: const Uuid().v4(),
        userId: user.id,
        answers: _answers.entries.map((e) => RiskAnswer(
          questionIndex: e.key,
          answerIndex: e.value,
          score: riskQuestions[e.key].options[e.value].score,
        )).toList(),
        totalScore: totalScore,
        riskLevel: riskLevel,
        assessedAt: DateTime.now(),
      );
      
      await ref.read(currentUserProvider.notifier).saveRiskAssessment(assessment);
      
      if (mounted) {
        _showResultDialog(assessment);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  
  void _showResultDialog(RiskAssessment assessment) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('风险评估结果'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    assessment.riskLevel.displayName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '总分: ${assessment.totalScore} 分',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              assessment.riskLevel.description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('开始投资'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('风险评估'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: _progress,
            minHeight: 4,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第 ${_currentIndex + 1} 题 / 共 ${riskQuestions.length} 题',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(_progress * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          
          // 问题页面
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: riskQuestions.length,
              itemBuilder: (context, index) {
                final question = riskQuestions[index];
                return _buildQuestionPage(question);
              },
            ),
          ),
          
          // 底部按钮
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevQuestion,
                      child: const Text('上一题'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 16),
                Expanded(
                  flex: _currentIndex > 0 ? 1 : 2,
                  child: FilledButton(
                    onPressed: _answers[_currentIndex] != null && !_loading
                      ? _nextQuestion
                      : null,
                    child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentIndex < riskQuestions.length - 1 
                          ? '下一题' : '完成测评'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionPage(RiskQuestion question) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分类标签
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              question.category,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontSize: 12,
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // 问题
          Text(
            question.question,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 选项
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _answers[question.index] == index;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => _selectAnswer(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                            width: 2,
                          ),
                          color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        ),
                        child: isSelected
                          ? Icon(
                              Icons.check,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            )
                          : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          option.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
