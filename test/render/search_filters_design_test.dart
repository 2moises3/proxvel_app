import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/controllers/search_controller.dart';
import 'package:proxvell_app/integration/services/destination_service.dart';
import 'package:proxvell_app/integration/local/local_storage_service.dart';
import 'package:proxvell_app/views/search/widgets/search_filter_sheet.dart';

void main() {
  testWidgets(
    'filters keep drafts local and return complete criteria on apply',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final ctrl = SearchController(DestinationService(), LocalStorageService())
        ..availableRegions = ['Cusco', 'Ica']
        ..availableCategories = ['Naturaleza', 'Arqueología']
        ..availableCostLevels = ['bajo', 'medio', 'alto']
        ..filters = const SearchFilters(
          query: 'Perú',
          climate: 'frio',
          month: 7,
        )
        ..aiSortEnabled = true;
      final fonts = FontLoader('Outfit');
      for (final weight in ['Regular', 'Medium', 'SemiBold']) {
        fonts.addFont(
          rootBundle.load('assets/fonts/outfit/Outfit-$weight.ttf'),
        );
      }
      await fonts.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final captureKey = GlobalKey();
      SearchFilters? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'Outfit'),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showModalBottomSheet<SearchFilters>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => FractionallySizedBox(
                      heightFactor: .9,
                      child: RepaintBoundary(
                        key: captureKey,
                        child: SearchFilterSheet(controller: ctrl),
                      ),
                    ),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Naturaleza'));
      await tester.pumpAndSettle();
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text('Lugar')));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../proxvel_landing/.artifacts/search-filters.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      await mouse.removePointer();
      expect(ctrl.filters.category, isNull);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(result?.category, 'Naturaleza');
      expect(result?.month, 7);
      expect(result?.climate, 'frio');
      expect(result?.query, 'Perú');
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Limpiar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(result?.hasActiveFilters, false);
      expect(result?.month, isNull);
      expect(ctrl.filters.climate, 'frio');
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cerrar filtros'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
