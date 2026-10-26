import '../navigation/profile_transition.dart';
import '../../views/profile/widgets/about_proxvel_sheet.dart';
import '../widgets/navigation/navigation_island_transition.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/destination_opening.dart';
import '../../views/auth/welcome_screen.dart';
import '../../views/auth/widgets/auth_backdrop.dart';
import '../../views/auth/login_screen.dart';
import '../../views/auth/session_ready_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/residence_gate_screen.dart';
import '../../views/onboarding/onboarding_profile_screen.dart';

import '../../views/main/main_layout.dart';
import '../../views/destination/destination_detail_screen.dart';
import '../../views/search/search_results_screen.dart';
import '../../views/favorites/favorites_screen.dart';
import '../../views/profile/change_password_screen.dart';
import '../../views/notifications/notifications_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/reset_password_screen.dart';
import '../../views/profile/profile_screen.dart';
import '../../views/profile/app_update_screen.dart';
import '../../views/profile/edit_profile_screen.dart';
import '../../views/profile/preferences_screen.dart';
import '../../views/profile/my_reviews_screen.dart';
import '../../views/feedback/feedback_screen.dart';
import '../../views/splash/splash_screen.dart';
import '../../views/map/map_screen.dart';
import '../../views/map/destination_map_screen.dart';
import '../../views/archived/archived_screen.dart';
import '../../views/legal/legal_document_screen.dart';
import '../../views/legal/privacy_legal_screen.dart';
import '../../views/legal/my_data_screen.dart';
import '../../views/legal/delete_account_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  observers: [authRouteObserver, navigationIslandObserver],
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/intro', redirect: (context, state) => '/welcome'),
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: WelcomeScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: '/session-ready',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SessionReadyScreen(),
        transitionDuration: const Duration(milliseconds: 420),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: RegisterScreen()),
    ),
    GoRoute(
      path: '/register-residence',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ResidenceGateScreen(mode: ResidenceGateMode.registration),
      ),
    ),
    GoRoute(
      path: '/residence-gate',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ResidenceGateScreen(mode: ResidenceGateMode.fallback),
      ),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingProfileScreen(),
    ),

    GoRoute(
      path: '/main',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: MainLayout()),
    ),
    GoRoute(
      path: '/destination/:id',
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        final source = state.uri.queryParameters['source'] ?? 'explore';
        final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
        return CustomTransitionPage(
          key: state.pageKey,
          child: DestinationDetailScreen(
            destinationId: id,
            opening: state.extra is DestinationOpening
                ? state.extra as DestinationOpening
                : null,
            source: source,
            month: month,
          ),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(opacity: curved, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        final category = state.uri.queryParameters['category'];
        final autoOpenFilters =
            state.uri.queryParameters['open_filters'] == 'true';
        return CustomTransitionPage(
          key: state.pageKey,
          child: SearchResultsScreen(
            initialQuery: query,
            initialCategory: category,
            autoOpenFilters: autoOpenFilters,
          ),
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
                reverseCurve: Curves.easeInCubic,
              ),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/updates',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const AppUpdateScreen()),
    ),
    GoRoute(
      path: '/profile/edit',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const EditProfileScreen()),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final extra = (state.extra as Map?) ?? const {};
        return ResetPasswordScreen(
          email: (extra['email'] ?? '') as String,
          supportEmail: extra['supportEmail'] as String?,
          expiresMinutes: (extra['expiresMinutes'] as int?) ?? 15,
        );
      },
    ),
    GoRoute(
      path: '/notifications',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificationsScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: '/profile/change-password',
      pageBuilder: (context, state) => profileTransition(
        context,
        state.pageKey,
        const ChangePasswordScreen(),
      ),
    ),
    GoRoute(
      path: '/profile/about',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const AboutProxvelScreen()),
    ),
    GoRoute(
      path: '/profile/preferences',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const PreferencesScreen()),
    ),
    GoRoute(
      path: '/profile/my-reviews',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const MyReviewsScreen()),
    ),
    GoRoute(
      path: '/feedback/:destinationId',
      builder: (context, state) {
        final destId = state.pathParameters['destinationId']!;
        return FeedbackScreen(destinationId: destId);
      },
    ),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(
      path: '/map/destination/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return DestinationMapScreen(destinationId: id);
      },
    ),
    GoRoute(
      path: '/archived',
      builder: (context, state) => const ArchivedScreen(),
    ),
    GoRoute(
      path: '/legal',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const PrivacyLegalScreen()),
    ),
    GoRoute(
      path: '/legal/doc/:id',
      builder: (context, state) =>
          LegalDocumentScreen.byId(state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/legal/my-data',
      pageBuilder: (context, state) =>
          profileTransition(context, state.pageKey, const MyDataScreen()),
    ),
    GoRoute(
      path: '/legal/delete-account',
      pageBuilder: (context, state) => profileTransition(
        context,
        state.pageKey,
        const DeleteAccountScreen(),
      ),
    ),
  ],
);
