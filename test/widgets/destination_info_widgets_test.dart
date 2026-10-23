import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/models/destination_model.dart';
import 'package:proxvell_app/models/tourism_catalog_model.dart';
import 'package:proxvell_app/views/destination/widgets/key_info_grid.dart';
import 'package:proxvell_app/views/destination/widgets/practical_info_card.dart';

DestinationModel dest({
  String category = '',
  String region = '',
  String city = '',
}) => DestinationModel(
  id: 'x',
  name: 'Destino',
  city: city,
  region: region,
  category: category,
  description: '',
  imageUrl: '',
  averageCost: 0,
  climate: '',
  crowdLevel: '',
  rating: 0,
  aspects: const [],
);

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('Datos del lugar muestra solo ubicación y altitud confirmadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        KeyInfoGrid(
          destination: dest(category: 'Arqueología', region: 'Cusco'),
          tourismInfo: TourismCatalogModel(
            altitudeM: 2430,
            difficulty: 'moderada',
          ),
        ),
      ),
    );
    expect(find.text('Cusco'), findsOneWidget);
    expect(find.text('2430 m s. n. m.'), findsOneWidget);
    expect(
      find.text('Arqueología'),
      findsNothing,
      reason: 'La categoría ya figura en la decisión rápida del detalle',
    );
    expect(find.text('Moderada'), findsNothing);
    expect(find.text('Costo estimado'), findsNothing);
    expect(find.text('N/A'), findsNothing);
  });

  testWidgets('Información clave desaparece si no hay ningún dato', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(KeyInfoGrid(destination: dest())));
    expect(find.text('Datos del lugar'), findsNothing);
  });

  testWidgets(
    'Prepara tu visita muestra lo cargado y el botón del sitio oficial',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          PracticalInfoCard(
            info: TourismCatalogModel(
              recommendedDuration: 'Medio día',
              howToGet: 'Bus desde la ciudad',
              officialWebsite: 'https://tuboleto.cultura.pe',
            ),
          ),
        ),
      );
      expect(find.text('Tiempo recomendado'), findsOneWidget);
      expect(find.text('Medio día'), findsOneWidget);
      expect(find.text('Cómo llegar'), findsOneWidget);
      expect(find.text('Antes de ir'), findsNothing);
      expect(find.text('Abrir sitio oficial'), findsOneWidget);
    },
  );

  testWidgets('Prepara tu visita no aparece vacía', (tester) async {
    await tester.pumpWidget(
      wrap(PracticalInfoCard(info: TourismCatalogModel())),
    );
    expect(find.text('Prepara tu visita'), findsNothing);
    await tester.pumpWidget(wrap(const PracticalInfoCard()));
    expect(find.text('Prepara tu visita'), findsNothing);
  });
}
