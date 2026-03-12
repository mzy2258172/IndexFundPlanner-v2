import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_guard.dart';
import '../../features/portfolio/presentation/pages/portfolio_page.dart';
import '../../features/portfolio/presentation/pages/portfolio_detail_page.dart';
import '../../features/portfolio/presentation/pages/add_holding_page.dart';
import '../../features/fund/presentation/pages/fund_list_page.dart';
import '../../features/fund/presentation/pages/fund_detail_page.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/user/presentation/pages/login_page.dart';
import '../../features/user/presentation/pages/risk_assessment_page.dart';
import '../../features/plan/presentation/pages/create_plan_page.dart';
import '../../features/plan/presentation/pages/plan_detail_page.dart';
import '../../shared/pages/home_page.dart';
import '../../shared/pages/settings_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = ref.read(isLoggedInProvider);
      final isLoginPage = state.matchedLocation == '/login';
      final isRiskAssessmentPage = state.matchedLocation == '/risk-assessment';
      
      // 未登录跳转到登录页
      if (!isLoggedIn && !isLoginPage) {
        return '/login';
      }
      
      // 已登录检查是否需要风险测评
      if (isLoggedIn && !isRiskAssessmentPage) {
        final needsRisk = ref.read(currentUserProvider.notifier).needsRiskAssessment();
        if (needsRisk) {
          return '/risk-assessment';
        }
      }
      
      return null;
    },
    routes: [
      // 登录
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      
      // 风险评估
      GoRoute(
        path: '/risk-assessment',
        name: 'risk-assessment',
        builder: (context, state) => const RiskAssessmentPage(),
      ),
      
      // 首页
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      
      // 投资组合管理
      GoRoute(
        path: '/portfolio',
        name: 'portfolio',
        builder: (context, state) => const PortfolioPage(),
      ),
      
      // 投资组合详情
      GoRoute(
        path: '/portfolio/:id',
        name: 'portfolio-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PortfolioDetailPage(portfolioId: id);
        },
      ),
      
      // 添加持仓
      GoRoute(
        path: '/add-holding',
        name: 'add-holding',
        builder: (context, state) {
          final portfolioId = state.uri.queryParameters['portfolioId'];
          return AddHoldingPage(portfolioId: portfolioId);
        },
      ),
      
      // 基金列表
      GoRoute(
        path: '/funds',
        name: 'funds',
        builder: (context, state) => const FundListPage(),
      ),
      
      // 基金详情
      GoRoute(
        path: '/fund/:code',
        name: 'fund-detail',
        builder: (context, state) {
          final code = state.pathParameters['code'] ?? '';
          return FundDetailPage(fundCode: code);
        },
      ),
      
      // 分析
      GoRoute(
        path: '/analytics',
        name: 'analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
      
      // 设置
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      
      // 创建投资计划
      GoRoute(
        path: '/create-plan',
        name: 'create-plan',
        builder: (context, state) {
          final fundCode = state.uri.queryParameters['fundCode'];
          return CreatePlanPage(fundCode: fundCode);
        },
      ),
      
      // 计划详情
      GoRoute(
        path: '/plan/:id',
        name: 'plan-detail',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return PlanDetailPage(planId: id);
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('页面未找到: ${state.error}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/home'),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    ),
  );
});

// 简化的认证守卫 Provider
final isLoggedInProvider = Provider<bool>((ref) {
  final userState = ref.watch(currentUserProvider);
  return userState.maybeWhen(
    data: (user) => user != null,
    orElse: () => false,
  );
});

// 认证守卫（不再需要单独文件）
class AuthGuard {
  static String? redirect(Ref ref, String location) {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (!isLoggedIn && location != '/login') {
      return '/login';
    }
    return null;
  }
}
