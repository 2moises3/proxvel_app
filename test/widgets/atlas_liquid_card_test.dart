import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proxvell_app/core/theme/app_theme.dart';
import 'package:proxvell_app/core/widgets/cards/liquid_progress_visit_card.dart';
import 'package:proxvell_app/models/visit_model.dart';

void main() {
  testWidgets('LiquidProgressVisitCard muestra tiempo restante cuando está en progreso', (tester) async {
    final visit = VisitModel(
      visitId: 'vis-1234',
      destinationId: 'dest-1',
      destinationName: 'Parque de la Reserva',
      visitStatus: 'in_progress',
      dwellMinutes: 6,
      minDwellMinutes: 20,
      remainingMinutes: 14,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LiquidProgressVisitCard(
            visit: visit,
          ),
        ),
      ),
    );

    // Debe mostrar el nombre del destino
    expect(find.text('Parque de la Reserva'), findsOneWidget);
    // Debe mostrar el porcentaje calculado: 6/20 = 30%
    expect(find.text('30%'), findsOneWidget);
    // Debe mostrar el texto de minutos restantes
    expect(find.text('Faltan 14 min de permanencia para sellar.'), findsOneWidget);
    // Aún no debe mostrar el botón "Sellar Visita"
    expect(find.text('Sellar Visita'), findsNothing);
  });

  testWidgets('LiquidProgressVisitCard muestra botón de sellar al cumplir el tiempo', (tester) async {
    bool verifyClicked = false;
    final completedVisit = VisitModel(
      visitId: 'vis-5678',
      destinationId: 'dest-2',
      destinationName: 'Machu Picchu',
      visitStatus: 'in_progress',
      dwellMinutes: 20,
      minDwellMinutes: 20,
      remainingMinutes: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: LiquidProgressVisitCard(
            visit: completedVisit,
            onVerify: () => verifyClicked = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Debe mostrar 100%
    expect(find.text('100%'), findsOneWidget);
    // Debe mostrar el badge de permanencia completada
    expect(find.text('¡Permanencia completada!'), findsOneWidget);
    // Debe mostrar el botón de Sellar Visita
    final verifyButton = find.text('Sellar Visita');
    expect(verifyButton, findsOneWidget);

    // Tocar el botón de Sellar
    await tester.tap(verifyButton);
    await tester.pump();
    expect(verifyClicked, isTrue);
  });
}
