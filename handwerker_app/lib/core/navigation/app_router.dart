import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:handwerker_app/data/providers/app_providers.dart';
import 'package:handwerker_app/presentation/screens/auth/login_screen.dart';
import 'package:handwerker_app/presentation/screens/auth/otp_screen.dart';
import 'package:handwerker_app/presentation/screens/auth/onboarding_screen.dart';
import 'package:handwerker_app/presentation/screens/auth/consent_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/customer_shell.dart';
import 'package:handwerker_app/presentation/screens/customer/home_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/create_order_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/proposals_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/order_tracking_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/order_detail_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/orders_list_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/rating_screen.dart';
import 'package:handwerker_app/presentation/screens/customer/profile_screen.dart';
import 'package:handwerker_app/presentation/screens/craftsman/craftsman_shell.dart';
import 'package:handwerker_app/presentation/screens/craftsman/craftsman_home_screen.dart';
import 'package:handwerker_app/presentation/screens/craftsman/job_request_screen.dart';
import 'package:handwerker_app/presentation/screens/craftsman/active_job_screen.dart';
import 'package:handwerker_app/presentation/screens/craftsman/wallet_screen.dart';
import 'package:handwerker_app/presentation/screens/craftsman/craftsman_profile_screen.dart';
import 'package:handwerker_app/presentation/screens/admin/admin_screens.dart';
import 'package:handwerker_app/presentation/screens/shared/chat_screen.dart';
import 'package:handwerker_app/presentation/screens/shared/notifications_screen.dart';

// ── Route names ─────────────────────────────────────────────
class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String consent = '/consent';

  // Customer
  static const String customerHome = '/customer';
  static const String createOrder = '/customer/create-order';
  static const String proposals = '/customer/proposals';
  static const String orderTracking = '/customer/tracking';
  static const String customerOrders = '/customer/orders';
  static const String orderDetail = '/customer/order';
  static const String rating = '/customer/rating';
  static const String customerProfile = '/customer/profile';

  // Craftsman
  static const String craftsmanHome = '/craftsman';
  static const String jobRequest = '/craftsman/job-request';
  static const String activeJob = '/craftsman/active-job';
  static const String wallet = '/craftsman/wallet';
  static const String craftsmanProfile = '/craftsman/profile';

  // Admin
  static const String adminHome = '/admin';

  // Shared
  static const String chat = '/chat';
  static const String notifications = '/notifications';
}

/// Notifies GoRouter whenever the auth state changes – without recreating
/// the entire GoRouter instance (which would tear down the whole widget tree
/// and re-trigger every provider, including admin data-fetching providers).
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthChangeNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.onboarding,
    debugLogDiagnostics: true,
    // refreshListenable fires on every auth change without recreating GoRouter.
    refreshListenable: notifier,
    redirect: (context, state) {
      // ref.read is intentional: the notifier already triggered re-evaluation.
      final authState = ref.read(authProvider);
      final isAuth = authState.status == AuthStatus.authenticated;
      final isAuthRoute = state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.otp ||
          state.matchedLocation == AppRoutes.onboarding;

      if (!isAuth && !isAuthRoute) return AppRoutes.login;
      if (isAuth && isAuthRoute) {
        if (authState.requiresConsent) return AppRoutes.consent;
        if (authState.role == UserRole.admin) return AppRoutes.adminHome;
        return authState.role == UserRole.craftsman
            ? AppRoutes.craftsmanHome
            : AppRoutes.customerHome;
      }
      return null;
    },
    routes: [
      // ── Auth ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (ctx, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (ctx, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (ctx, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.consent,
        builder: (ctx, state) => const ConsentScreen(),
      ),

      // ── Customer Shell ──────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => CustomerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.customerHome,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const HomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.customerOrders,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const OrdersListScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.customerProfile,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const ProfileScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // ── Customer Full-Screen Routes ─────────────────────
      GoRoute(
        path: AppRoutes.createOrder,
        pageBuilder: (ctx, state) => CustomTransitionPage(
          child: const CreateOrderScreen(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.proposals}/:orderId',
        builder: (ctx, state) => ProposalsScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orderTracking}/:orderId',
        builder: (ctx, state) => OrderTrackingScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.orderDetail}/:orderId',
        builder: (ctx, state) => OrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.rating}/:orderId',
        pageBuilder: (ctx, state) => CustomTransitionPage(
          child: RatingScreen(
            orderId: state.pathParameters['orderId']!,
          ),
          transitionsBuilder: _slideUpTransition,
        ),
      ),

      // ── Craftsman Shell ─────────────────────────────────
      ShellRoute(
        builder: (ctx, state, child) => CraftsmanShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.craftsmanHome,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const CraftsmanHomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.wallet,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const WalletScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: AppRoutes.craftsmanProfile,
            pageBuilder: (ctx, state) => CustomTransitionPage(
              child: const CraftsmanProfileScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // ── Craftsman Full-Screen Routes ────────────────────
      GoRoute(
        path: '${AppRoutes.jobRequest}/:orderId',
        builder: (ctx, state) => JobRequestScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.activeJob}/:orderId',
        builder: (ctx, state) => ActiveJobScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),

      // ── Admin ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminHome,
        builder: (ctx, state) => const AdminShell(),
      ),

      // ── Shared ──────────────────────────────────────────
      GoRoute(
        path: '${AppRoutes.chat}/:orderId',
        builder: (ctx, state) => ChatScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (ctx, state) => const NotificationsScreen(),
      ),
    ],
  );
});

// ── Page Transitions ──────────────────────────────────────────
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final tween = Tween(begin: const Offset(0, 0.1), end: Offset.zero)
      .chain(CurveTween(curve: Curves.easeOutCubic));
  return SlideTransition(
    position: animation.drive(tween),
    child: FadeTransition(opacity: animation, child: child),
  );
}
