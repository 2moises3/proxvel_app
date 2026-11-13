import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/widgets/navigation/proxvel_bottom_navigation.dart';

void main() {
  testWidgets('island changes tabs without overflow and respects safe area', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var index = 0;
    await tester.pumpWidget(MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(viewPadding: const EdgeInsets.only(bottom: 34), textScaler: const TextScaler.linear(1.5)), child: child!),
      home: StatefulBuilder(builder: (context, update) => Scaffold(extendBody: true,
        body: ListView(children: List.generate(30, (i) => ListTile(title: Text('Destino $i')))),
        bottomNavigationBar: ProxvelBottomNavigation(currentIndex: index, onTap: (value) => update(() => index = value)),
      )),
    ));
    for (final (i, label) in ['Inicio', 'Mapa', 'Favoritos', 'Perfil'].indexed) {
      await tester.tap(find.byTooltip(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(index, i);
      expect(find.text(label), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    expect(tester.getBottomLeft(find.byTooltip('Perfil')).dy, lessThan(640 - 34));
  });
}
