import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:proxvell_app/core/widgets/navigation/navigation_island_transition.dart';
import 'package:proxvell_app/core/widgets/navigation/proxvel_bottom_navigation.dart';

void main() {
  testWidgets(
    'island stays above opaque routes; blur does not jump; rapid return is continuous',
    (tester) async {
      final controller = NavigationIslandController();
      late BuildContext mainContext;
      final router = GoRouter(
        initialLocation: '/main',
        observers: [NavigationIslandObserver(controller)],
        routes: [
          GoRoute(
            path: '/main',
            pageBuilder: (_, _) => NoTransitionPage(
              child: Builder(
                builder: (context) {
                  mainContext = context;
                  return const Scaffold(body: Text('Main'));
                },
              ),
            ),
          ),
          GoRoute(
            path: '/search',
            builder: (_, _) => const Scaffold(body: Text('Search')),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (context, child) =>
              NavigationIslandHost(controller: controller, child: child!),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ProxvelBottomNavigation), findsNothing);
      // Registration can arrive after the observer event (startup/hot reload).
      controller.attach(
        route: ModalRoute.of(mainContext)!,
        index: 0,
        onTap: (_) {},
      );
      await tester.pumpAndSettle();
      ProxvelBottomNavigation bar() =>
          tester.widget(find.byType(ProxvelBottomNavigation));
      expect(bar().islandOffset, 0);
      router.push('/search');
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(bar().islandOffset, lessThan(0));
      expect(bar().backdropOffset, 0);
      await tester.pump(const Duration(milliseconds: 250));
      expect(bar().islandOffset, greaterThan(0));
      expect(bar().backdropOffset, bar().islandOffset);
      expect(find.byType(ProxvelBottomNavigation), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      // The global layer is the last painted child, above the route Navigator.
      final hostStack = tester.widget<Stack>(
        find
            .descendant(
              of: find.byType(NavigationIslandHost),
              matching: find.byType(Stack),
            )
            .first,
      );
      expect(hostStack.children.last, isA<AnimatedBuilder>());
      final beforeReturn = bar().islandOffset;
      router.pop();
      await tester.pump();
      expect(bar().islandOffset, closeTo(beforeReturn, .01));
      await tester.pumpAndSettle();
      expect(bar().islandOffset, 0);
      router.push('/search');
      await tester.pumpAndSettle();
      expect(find.byType(ProxvelBottomNavigation), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(bar().islandOffset, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('reduced motion hides immediately without a bounce', (
    tester,
  ) async {
    final controller = NavigationIslandController()
      ..update(visible: true, onTap: (_) {});
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: NavigationIslandHost(controller: controller, child: child!),
        ),
        home: const Scaffold(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ProxvelBottomNavigation>(find.byType(ProxvelBottomNavigation))
          .islandOffset,
      0,
    );
    controller.update(visible: false);
    await tester.pump();
    expect(find.byType(ProxvelBottomNavigation), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
