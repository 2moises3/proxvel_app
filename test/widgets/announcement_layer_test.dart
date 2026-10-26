import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/widgets/announcements/announcement_modal.dart';
import 'package:proxvell_app/core/widgets/navigation/navigation_island_transition.dart';
import 'package:proxvell_app/models/announcement_model.dart';

void main() {
  for (final placement in ['app_start', 'global_modal']) {
    testWidgets('$placement barrier covers the global navigation island', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var taps = 0;
      var showAd = false;
      late StateSetter update;
      final controller = NavigationIslandController()
        ..update(visible: true, onTap: (_) => taps++);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              NavigationIslandHost(controller: controller, child: child!),
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: Stack(
                  children: [
                    const SizedBox.expand(),
                    if (showAd)
                      AnnouncementModalOverlay(
                        announcement: AnnouncementModel(
                          id: 1,
                          title: 'Aviso de prueba',
                          message: 'Contenido del anuncio',
                          placement: placement,
                          templateType: 'minimal_notice',
                        ),
                        onClose: () => setState(() => showAd = false),
                        onAction: () {},
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final navPoint = tester.getCenter(find.text('Inicio'));
      update(() => showAd = true);
      await tester.pumpAndSettle();
      expect(find.text('Aviso de prueba'), findsOneWidget);
      await tester.tapAt(navPoint);
      await tester.pumpAndSettle();
      expect(taps, 0);
      if (placement == 'global_modal') {
        expect(find.text('Aviso de prueba'), findsOneWidget);
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();
      }
      expect(find.text('Aviso de prueba'), findsNothing);
      await tester.tapAt(navPoint);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }
}
