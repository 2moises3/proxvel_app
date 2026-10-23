import 'controllers/notifications_controller.dart';
import 'integration/services/notification_service.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'integration/api/api_client.dart';
import 'integration/local/local_storage_service.dart';
import 'integration/local/secure_token_storage.dart';
import 'integration/services/profile_service.dart';
import 'integration/services/destination_service.dart';
import 'integration/services/recommendation_service.dart';
import 'integration/services/feedback_service.dart';
import 'integration/services/tourism_service.dart';
import 'integration/services/review_service.dart';
import 'integration/services/user_service.dart';
import 'integration/services/auth_service.dart';
import 'integration/services/favorites_service.dart';
import 'integration/services/tourism_map_service.dart';
import 'integration/services/announcement_service.dart';
import 'integration/services/archive_service.dart';
import 'controllers/archive_controller.dart';
import 'controllers/auth_controller.dart';
import 'controllers/announcement_controller.dart';
import 'controllers/home_controller.dart';
import 'controllers/onboarding_controller.dart';
import 'controllers/search_controller.dart';
import 'controllers/recommendation_controller.dart';
import 'controllers/destination_controller.dart';
import 'controllers/favorites_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/feedback_controller.dart';
import 'controllers/my_reviews_controller.dart';
import 'controllers/tourism_map_controller.dart';

class ProxvelApp extends StatelessWidget {
  final LocalStorageService storageService;

  const ProxvelApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<LocalStorageService>.value(value: storageService),
        Provider<SecureTokenStorage>(create: (_) => SecureTokenStorage()),
        ProxyProvider<SecureTokenStorage, ApiClient>(
          update: (_, secureStorage, previous) => ApiClient(secureStorage: secureStorage),
        ),
        ProxyProvider2<LocalStorageService, ApiClient, ProfileService>(
          update: (_, storage, api, previous) =>
              ProfileService(storage, apiClient: api),
        ),
        ProxyProvider2<LocalStorageService, ApiClient, FeedbackService>(
          update: (_, storage, api, previous) => FeedbackService(storage, apiClient: api),
        ),
        ProxyProvider2<LocalStorageService, ApiClient, DestinationService>(
          update: (_, storage, api, previous) =>
              DestinationService(apiClient: api, storage: storage),
        ),
        ProxyProvider<ApiClient, TourismService>(
          update: (_, api, previous) => TourismService(apiClient: api),
        ),
        ProxyProvider<ApiClient, ReviewService>(
          update: (_, api, previous) => ReviewService(apiClient: api),
        ),
        ProxyProvider<ApiClient, RecommendationService>(
          update: (_, api, previous) => RecommendationService(apiClient: api),
        ),
        ProxyProvider<ApiClient, UserService>(
          update: (_, api, previous) => UserService(apiClient: api),
        ),
        ProxyProvider<ApiClient, AuthService>(
          update: (_, api, previous) => AuthService(apiClient: api),
        ),
        ProxyProvider<ApiClient, FavoritesService>(
          update: (_, api, previous) => FavoritesService(apiClient: api),
        ),
        ProxyProvider<ApiClient, ArchiveService>(
          update: (_, api, previous) => ArchiveService(apiClient: api),
        ),
        ProxyProvider<ApiClient, TourismMapService>(
          update: (_, api, previous) => TourismMapService(apiClient: api),
        ),
        ProxyProvider<ApiClient, NotificationService>(
          update: (_, api, previous) => NotificationService(apiClient: api),
        ),
        ProxyProvider<ApiClient, AnnouncementService>(
          update: (_, api, previous) => AnnouncementService(apiClient: api),
        ),

        // Controllers
        ChangeNotifierProxyProvider4<LocalStorageService, SecureTokenStorage, UserService, AuthService, AuthController>(
          create: (context) => AuthController(context.read<LocalStorageService>(), context.read<SecureTokenStorage>(), context.read<UserService>(), context.read<AuthService>()),
          update: (context, local, secure, userSvc, authSvc, auth) => auth ?? AuthController(local, secure, userSvc, authSvc),
        ),
        ChangeNotifierProxyProvider2<DestinationService, LocalStorageService, HomeController>(
          create: (context) => HomeController(
            context.read<DestinationService>(),
            context.read<LocalStorageService>(),
          ),
          update: (context, destSvc, localSvc, ctl) => ctl ?? HomeController(destSvc, localSvc),
        ),
        ChangeNotifierProxyProvider<ProfileService, OnboardingController>(
          create: (context) => OnboardingController(context.read<ProfileService>()),
          update: (context, profileSvc, ctl) => ctl ?? OnboardingController(profileSvc),
        ),
        ChangeNotifierProxyProvider2<DestinationService, LocalStorageService, SearchController>(
          create: (context) => SearchController(
            context.read<DestinationService>(),
            context.read<LocalStorageService>(),
          ),
          update: (context, destSvc, localSvc, ctl) => ctl ?? SearchController(destSvc, localSvc),
        ),
        ChangeNotifierProxyProvider<RecommendationService, RecommendationController>(
          create: (context) => RecommendationController(context.read<RecommendationService>()),
          update: (context, recSvc, ctl) => ctl ?? RecommendationController(recSvc),
        ),
        ChangeNotifierProxyProvider3<DestinationService, TourismService, ReviewService, DestinationController>(
          create: (context) => DestinationController(
            context.read<DestinationService>(),
            context.read<TourismService>(),
            context.read<ReviewService>(),
          ),
          update: (context, destSvc, tourismSvc, reviewSvc, ctl) => 
            ctl ?? DestinationController(destSvc, tourismSvc, reviewSvc),
        ),
        ChangeNotifierProxyProvider<FavoritesService, FavoritesController>(
          create: (context) => FavoritesController(context.read<FavoritesService>()),
          update: (context, favSvc, ctl) => ctl ?? FavoritesController(favSvc),
        ),
        ChangeNotifierProxyProvider<ArchiveService, ArchiveController>(
          create: (context) => ArchiveController(context.read<ArchiveService>()),
          update: (context, arcSvc, ctl) => ctl ?? ArchiveController(arcSvc),
        ),
        ChangeNotifierProxyProvider3<ProfileService, LocalStorageService, UserService, ProfileController>(
          create: (context) => ProfileController(
            context.read<ProfileService>(),
            context.read<LocalStorageService>(),
            userService: context.read<UserService>(),
          ),
          update: (context, profileSvc, localSvc, userSvc, ctl) => 
            ctl ?? ProfileController(profileSvc, localSvc, userService: userSvc),
        ),
        ChangeNotifierProxyProvider<FeedbackService, FeedbackController>(
          create: (context) => FeedbackController(context.read<FeedbackService>()),
          update: (context, feedbackSvc, ctl) => ctl ?? FeedbackController(feedbackSvc),
        ),
        ChangeNotifierProxyProvider<ReviewService, MyReviewsController>(
          create: (context) => MyReviewsController(context.read<ReviewService>()),
          update: (context, reviewSvc, ctl) => ctl ?? MyReviewsController(reviewSvc),
        ),
        ChangeNotifierProxyProvider<TourismMapService, TourismMapController>(
          create: (context) => TourismMapController(context.read<TourismMapService>()),
          update: (context, mapSvc, ctl) => ctl ?? TourismMapController(mapSvc),
        ),
        ChangeNotifierProxyProvider<NotificationService, NotificationsController>(
          create: (context) => NotificationsController(context.read<NotificationService>()),
          update: (context, svc, ctl) => ctl ?? NotificationsController(svc),
        ),
        ChangeNotifierProxyProvider<AnnouncementService, AnnouncementController>(
          create: (context) => AnnouncementController(context.read<AnnouncementService>()),
          update: (context, annSvc, ctl) => ctl ?? AnnouncementController(annSvc),
        ),
      ],
      child: const _SessionManager(
        child: _ProxvelMaterialApp(),
      ),
    );
  }
}

class _ProxvelMaterialApp extends StatelessWidget {
  const _ProxvelMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PROXVEL',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Escucha los cambios de sesión. Cuando detecta que el usuario cerró sesión
/// (o cambió), limpia el estado en memoria de los demás controladores
/// para evitar filtración de datos entre sesiones.
class _SessionManager extends StatefulWidget {
  final Widget child;
  const _SessionManager({required this.child});

  @override
  State<_SessionManager> createState() => _SessionManagerState();
}

class _SessionManagerState extends State<_SessionManager> {
  bool _wasAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Leer estado inicial sin escuchar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _wasAuthenticated = context.read<AuthController>().isAuthenticated;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthController>();
    final isAuth = auth.isAuthenticated;

    // Detectamos la transición de autenticado -> no autenticado (logout)
    if (_wasAuthenticated && !isAuth) {
      _clearAllControllers();
    }
    
    // También detectamos si un nuevo usuario hace login (transición a auth)
    // Para asegurarnos de que parta de un estado limpio
    if (!_wasAuthenticated && isAuth) {
      _clearAllControllers();
    }

    _wasAuthenticated = isAuth;
  }

  void _clearAllControllers() {
    // Usamos read() porque estamos en un callback reaccionando a un cambio
    context.read<FavoritesController>().clearState();
    context.read<RecommendationController>().clearState();
    context.read<ProfileController>().clearState();
    context.read<ArchiveController>().clearState();
    context.read<MyReviewsController>().clearState();
    context.read<NotificationsController>().clearState();
    context.read<DestinationService>().clearPersonalizedCache();
    // Si hay otros controladores con estado en memoria, se agregarían aquí
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
