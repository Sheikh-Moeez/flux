import 'package:go_router/go_router.dart';
import '../../screens/bills_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/mpin_screen.dart';
import '../../screens/main_scaffold.dart';
import '../../screens/home_screen.dart';
import '../../screens/stats_screen.dart';
import '../../screens/debt_screen.dart';
import '../../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../services/secure_storage_service.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    refreshListenable: authService,
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/mpin',
        name: 'mpin',
        builder: (context, state) {
          final modeStr = state.uri.queryParameters['mode'] ?? 'verify';
          final mode = modeStr == 'setup' ? MPINMode.setup : MPINMode.verify;
          return MPINScreen(mode: mode);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'bills',
                    name: 'bills',
                    builder: (context, state) => const BillsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/stats',
                name: 'stats',
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/debt',
                name: 'debt',
                builder: (context, state) => const DebtScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final isLoggedIn = authService.currentUser != null;
      final isLoggingIn = state.uri.toString() == '/login';
      final isSigningUp = state.uri.toString() == '/signup';
      final isMpin = state.uri.path == '/mpin';

      // 1. Not Logged In
      if (!isLoggedIn) {
        if (isLoggingIn || isSigningUp) return null;
        return '/login';
      }

      // 2. Logged In -> Check MPIN
      if (isLoggedIn) {
        // If not verified
        if (!authService.isMpinVerified) {
          // If already on MPIN screen, let it stay
          if (isMpin) return null;

          // Check if MPIN exists
          final hasMpin = await SecureStorageService.instance.hasMPIN();
          if (hasMpin) {
            return '/mpin?mode=verify';
          } else {
            return '/mpin?mode=setup';
          }
        }

        // If verified, but trying to access login/mpin -> redirect to home
        if (isLoggingIn || isSigningUp || isMpin) {
          return '/';
        }
      }

      return null;
    },
  );
}
