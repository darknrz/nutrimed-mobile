import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/recipes/presentation/screens/recipes_screen.dart';
import '../../features/recipe_detail/presentation/screens/recipe_detail_screen.dart';
import '../../features/chatbot/presentation/screens/chatbot_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../storage/secure_storage.dart';
import '../di/injection.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final storage   = sl<SecureStorage>();
      final hasToken  = await storage.hasToken();
      final location  = state.matchedLocation;
      final onLogin   = location == '/login';
      final onOnboard = location == '/onboarding';

      if (!hasToken) return onLogin ? null : '/login';

      if (hasToken && onLogin) {
        final needsOnboarding = await storage.getNeedsOnboarding();
        return needsOnboarding ? '/onboarding' : '/home';
      }

      if (hasToken && onOnboard) return null;

      return null;
    },
    routes: [
      GoRoute(path: '/login',
          builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/onboarding',
          builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/home',
          builder: (c, s) => const HomeScreen()),
      GoRoute(path: '/recipes',
          builder: (c, s) => const RecipesScreen()),

      // ── ÚNICA ruta de detalle — siempre pasa el recipe por extra ──
      GoRoute(
        path: '/recipes/:id',
        builder: (c, s) => RecipeDetailScreen(
          id:     s.pathParameters['id']!,
          recipe: s.extra as Map<String, dynamic>?,
        ),
      ),

      GoRoute(path: '/chat',
          builder: (c, s) => const ChatbotScreen()),
      GoRoute(path: '/profile',
          builder: (c, s) => const ProfileScreen()),
    ],
  );
}