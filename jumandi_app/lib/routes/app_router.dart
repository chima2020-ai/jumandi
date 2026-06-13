import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_setup_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/delivery/delivery_chat_screen.dart';
import '../screens/delivery/delivery_dashboard_screen.dart';
import '../screens/delivery/delivery_history_screen.dart';
import '../screens/delivery/delivery_profile_screen.dart';
import '../screens/delivery/delivery_requests_screen.dart';
import '../screens/delivery/delivery_shell.dart';
import '../screens/delivery/order_detail_screen.dart';
import '../screens/main/booking_screen.dart';
import '../screens/main/chat_screen.dart';
import '../screens/main/history_screen.dart';
import '../screens/main/home_map_screen.dart';
import '../screens/main/main_shell.dart';
import '../screens/main/profile_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/splash/brand_splash_screen.dart';
import '../screens/splash/loading_splash_screen.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      if (auth.loading) return null;

      final path = state.uri.path;
      const publicPaths = {
        '/',
        '/loading',
        '/onboarding',
        '/login',
        '/register',
        '/admin/login',
        '/admin/setup',
      };

      if (auth.isLoggedIn) {
        if (auth.needsEmailVerification) {
          if (path != '/otp') return '/otp';
          return null;
        }

        if (path == '/login' ||
            path == '/register' ||
            path == '/otp' ||
            path == '/admin/login' ||
            path == '/admin/setup') {
          return auth.homeRoute;
        }

        if (path.startsWith('/admin') && !auth.isAdmin) {
          return auth.homeRoute;
        }
        if (path.startsWith('/delivery') && !auth.isDelivery) {
          return auth.homeRoute;
        }
        if (path.startsWith('/home') && !auth.isCustomer) {
          return auth.homeRoute;
        }
      } else if (!publicPaths.contains(path)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const BrandSplashScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const LoadingSplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/otp', builder: (_, __) => const OtpScreen()),
      GoRoute(path: '/admin/login', builder: (_, __) => const AdminLoginScreen()),
      GoRoute(path: '/admin/setup', builder: (_, __) => const AdminSetupScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeMapScreen()),
          GoRoute(path: '/home/booking', builder: (_, __) => const BookingScreen()),
          GoRoute(path: '/home/history', builder: (_, __) => const HistoryScreen()),
          GoRoute(path: '/home/chat', builder: (_, __) => const ChatScreen()),
          GoRoute(
            path: '/home/chat/:bookingId',
            builder: (_, state) {
              final id = int.parse(state.pathParameters['bookingId']!);
              return ChatScreen(bookingId: id);
            },
          ),
          GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
      ShellRoute(
        builder: (_, __, child) => DeliveryShell(child: child),
        routes: [
          GoRoute(path: '/delivery', builder: (_, __) => const DeliveryDashboardScreen()),
          GoRoute(path: '/delivery/requests', builder: (_, __) => const DeliveryRequestsScreen()),
          GoRoute(path: '/delivery/history', builder: (_, __) => const DeliveryHistoryScreen()),
          GoRoute(path: '/delivery/profile', builder: (_, __) => const DeliveryProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/delivery/order/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return OrderDetailScreen(orderId: id);
        },
      ),
      GoRoute(
        path: '/delivery/chat/:bookingId',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['bookingId']!);
          return DeliveryChatScreen(bookingId: id);
        },
      ),
    ],
  );
}
