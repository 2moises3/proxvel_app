import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'proxvel_empty_state.dart';

class EmptyProfileForAiState extends StatelessWidget {
  final String message;
  final bool showAction;
  const EmptyProfileForAiState({
    super.key,
    this.message =
        'Con tu estilo de viaje e intereses podremos recomendarte destinos. También tendrás en cuenta el clima y la afluencia.',
    this.showAction = true,
  });

  @override
  Widget build(BuildContext context) => ProxvelEmptyState(
    icon: Icons.auto_awesome_rounded,
    title: 'Cuéntanos cómo te gusta viajar',
    subtitle: message,
    actionLabel: showAction ? 'Elegir mis preferencias' : null,
    onAction: showAction ? () => context.push('/profile/preferences') : null,
  );
}
