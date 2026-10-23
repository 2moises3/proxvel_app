import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../../core/widgets/navigation/proxvel_bottom_navigation.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  static MainLayoutState? of(BuildContext context) => context.findAncestorStateOfType<MainLayoutState>();

  @override
  State<MainLayout> createState() => MainLayoutState();
}

class MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final Set<int> _visitedTabs = {0};
  bool _warmPrefetchStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startWarmPrefetch();
    });
  }

  Future<void> _startWarmPrefetch() async {
    if (_warmPrefetchStarted) return;
    _warmPrefetchStarted = true;

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _visitedTabs.add(3)); // Perfil

    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _visitedTabs.add(2)); // Favoritos
  }

  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const HomeScreen(),
          _visitedTabs.contains(1) ? const MapScreen() : const SizedBox.shrink(),
          _visitedTabs.contains(2) ? const FavoritesScreen() : const SizedBox.shrink(),
          _visitedTabs.contains(3) ? const ProfileScreen() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: ProxvelBottomNavigation(
        currentIndex: _currentIndex,
        onTap: changeTab,
      ),
    );
  }
}
