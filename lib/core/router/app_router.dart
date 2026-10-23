import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../navigation/destination_opening.dart';
import '../../views/auth/welcome_screen.dart';
import '../../views/auth/widgets/auth_backdrop.dart';
import '../../views/auth/login_screen.dart';
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
  observers: [authRouteObserver],
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
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final source = state.uri.queryParameters['source'] ?? 'explore';
        final month = int.tryParse(state.uri.queryParameters['month'] ?? '');
        return DestinationDetailScreen(
          destinationId: id,
          opening: state.extra is DestinationOpening
              ? state.extra as DestinationOpening
              : null,
          source: source,
          month: month,
        );
      },
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) {
        final query = state.uri.queryParameters['q'] ?? '';
        final category = state.uri.queryParameters['category'];
        return SearchResultsScreen(
          initialQuery: query,
          initialCategory: category,
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
      path: '/profile/edit',
      builder: (context, state) => const EditProfileScreen(),
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
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/profile/change-password',
      builder: (context, state) => const ChangePasswordScreen(),
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),
    GoRoute(
      path: '/profile/my-reviews',
      builder: (context, state) => const MyReviewsScreen(),
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
      builder: (context, state) => const PrivacyLegalScreen(),
    ),
    GoRoute(
      path: '/legal/doc/:id',
      builder: (context, state) =>
          LegalDocumentScreen.byId(state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/legal/my-data',
      builder: (context, state) => const MyDataScreen(),
    ),
    GoRoute(
      path: '/legal/delete-account',
      builder: (context, state) => const DeleteAccountScreen(),
    ),
  ],
);
