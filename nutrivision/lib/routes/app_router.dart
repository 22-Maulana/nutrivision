import 'package:go_router/go_router.dart';
import '../features/splash/views/splash_screen.dart';
import '../features/onboarding/views/onboarding_screen.dart';
import '../features/main/views/main_wrapper_screen.dart';
import '../features/auth/views/login_screen.dart';
import '../features/auth/views/register_screen.dart';
import '../features/scan/views/scan_result_view.dart';
import '../features/scan/models/scan_response_model.dart';
import '../features/dashboard/views/nutrition_graph_view.dart';
import '../features/history/views/history_detail_view.dart';
import '../features/history/models/history_state.dart';
import '../features/chatbot/views/chatbot_view.dart';
import '../features/auth/views/otp_verification_screen.dart';
import '../features/dashboard/views/weekly_recap_view.dart';
import '../features/profile/views/about_app_view.dart';
import '../features/profile/views/edit_mother_profile_view.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const MainWrapperScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanResult,
      builder: (context, state) {
        final result = state.extra as ScanResponseModel;
        return ScanResultView(result: result);
      },
    ),
    GoRoute(
      path: AppRoutes.nutritionGraph,
      builder: (context, state) => const NutritionGraphView(),
    ),
    GoRoute(
      path: AppRoutes.historyDetail,
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        final meal = extra['meal'] as DailyMealItem;
        final date = extra['date'] as String;
        return HistoryDetailView(meal: meal, dateText: date);
      },
    ),
    GoRoute(
      path: AppRoutes.chatbot,
      builder: (context, state) => const ChatbotView(),
    ),
    GoRoute(
      path: AppRoutes.otpVerification,
      builder: (context, state) {
        final email = state.extra as String;
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.weeklyRecap,
      builder: (context, state) => const WeeklyRecapView(),
    ),
    GoRoute(
      path: AppRoutes.aboutApp,
      builder: (context, state) => const AboutAppView(),
    ),
    GoRoute(
      path: AppRoutes.editMotherProfile,
      builder: (context, state) => const EditMotherProfileView(),
    ),
  ],
);


