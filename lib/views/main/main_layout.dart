import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../integration/services/app_update_service.dart';
import '../home/home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/widgets/navigation/navigation_island_transition.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainLayoutState>();

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncNavigationIsland();
      _checkForUpdate();
    });
  }

  void _syncNavigationIsland() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null) {
      navigationIsland.attach(
        route: route,
        index: _currentIndex,
        onTap: changeTab,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncNavigationIsland(),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncNavigationIsland(),
    );
  }

  Future<void> _checkForUpdate() async {
    try {
      final release = await AppUpdateService().latestAvailable();
      if (!mounted || release == null) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Actualización disponible'),
          content: Text('PROXVEL ${release.versionName} ya está disponible.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Después'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.push('/profile/updates');
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      );
    } catch (_) {
      // La aplicación sigue funcionando si no hay red o falla la consulta.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => navigationIsland.detach(changeTab),
    );
    super.dispose();
  }

  void changeTab(int index) {
    if (!mounted) return;
    navigationIsland.update(index: index);
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          _visitedTabs.contains(1)
              ? const MapScreen(embedded: true)
              : const SizedBox.shrink(),
          _visitedTabs.contains(2)
              ? const FavoritesScreen()
              : const SizedBox.shrink(),
          _visitedTabs.contains(3)
              ? const ProfileScreen()
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 146 + MediaQuery.viewPaddingOf(context).bottom,
      ),
    );
  }
}
