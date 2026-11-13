import '../../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'proxvel_empty_state.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => ProxvelEmptyState(
    icon: Icons.cloud_off_outlined,
    title: context.l10n.uiNoPudimosCargarLaInformacion,
    subtitle: message,
    actionLabel: context.l10n.retry,
    onAction: onRetry,
  );
}
