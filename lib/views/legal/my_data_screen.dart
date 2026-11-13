import '../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';
import '../../integration/api/api_client.dart';
import '../../integration/services/auth_service.dart';
import 'legal_document_screen.dart';

/// Perfil → Privacidad y legal → Mis datos: qué guardamos, derechos y acciones de cuenta.
class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key});

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  bool _busy = false;

  Future<void> _logoutAll() async {
    if (_busy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.uiCerrarSesionEnTodosTusDispositivos),
        content: Text(
          context.l10n.uiSeCerraraTuSesionAquiY,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.uiCerrarSesiones),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      await context.read<AuthService>().logoutAll();
    } on ApiException catch (e) {
      // Si la sesión ya había vencido, el resultado es el mismo: terminar la sesión local.
      if (e.statusCode != 401) {
        if (mounted) setState(() => _busy = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.uiNoPudimosCerrarLasSesionesRevisa,
            ),
          ),
        );
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.uiNoPudimosCerrarLasSesionesRevisa2),
        ),
      );
      return;
    }
    await auth.logout();
    router.go('/welcome');
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.uiCerramosTuSesionEnTodosTus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LegalDocumentScreen(
      doc: myData,
      footer: [
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _busy ? null : _logoutAll,
          icon: const Icon(Icons.devices_rounded, size: 18),
          label: Text(context.l10n.uiCerrarSesionEnTodosMisDispositivos),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: AppSpace.section),
        FilledButton.icon(
          onPressed: _busy ? null : () => context.push('/legal/delete-account'),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: Text(context.l10n.deleteAccount),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
