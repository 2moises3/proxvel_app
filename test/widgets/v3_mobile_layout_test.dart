import 'package:proxvell_app/models/aspect_score_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/widgets/forms/traveler_type_selector.dart';
import 'package:proxvell_app/core/widgets/states/empty_profile_for_ai_state.dart';
import 'package:proxvell_app/views/destination/widgets/why_for_me_tab_content.dart';

void main() {
  for (final width in [320.0, 360.0, 390.0]) {
    testWidgets('V3 admite texto ampliado a $width dp', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: const TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    TravelerTypeSelector(value: 'economico_mochilero'),
                    SizedBox(height: 24),
                    WhyForMeTabContent(
                      compatibilityPercentage: 89,
                      label: 'Parcialmente recomendado',
                      explanation:
                          'Coincide con tus intereses. El contexto mensual también interviene en la posición.',
                      topAspects: [
                        'Valoración de precios',
                        'Atención y servicio',
                        'Atractivos turísticos',
                      ],
                      aspectScores: [
                        AspectScoreModel(
                          aspect: 'Valoración de precios',
                          score: .5,
                        ),
                        AspectScoreModel(
                          aspect: 'Atención y servicio',
                          score: .65,
                        ),
                        AspectScoreModel(
                          aspect: 'Atractivos turísticos',
                          score: .97,
                        ),
                      ],
                      climaContextScore: .91,
                      aforoContextScore: .23,
                      contextMonthName: 'septiembre',
                      shapBase: .4,
                      shapValues: {
                        'afinidad': .2,
                        'clima': .03,
                        'afluencia': -.01,
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Valoraciones de referencia'));
      await tester.tap(find.text('Valoraciones de referencia'));
      await tester.pumpAndSettle();
      expect(find.text('Atractivos turísticos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'completar perfil cabe en el espacio disponible bajo la cabecera',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 280,
              child: EmptyProfileForAiState(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Elegir mis preferencias'));
      expect(find.text('Elegir mis preferencias'), findsOneWidget);
    },
  );
}
