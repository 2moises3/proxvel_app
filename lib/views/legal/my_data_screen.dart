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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión en todos tus dispositivos'),
        content: const Text('Se cerrará tu sesión aquí y en cualquier otro dispositivo donde hayas entrado. Podrás volver a iniciar sesión cuando quieras.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cerrar sesiones')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthService>().logoutAll();
    } on ApiException catch (e) {
      // Si la sesión ya había vencido, el resultado es el mismo: terminar la sesión local.
      if (e.statusCode != 401) {
        if (mounted) setState(() => _busy = false);
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(const SnackBar(content: Text('No pudimos cerrar las sesiones. Revisa tu conexión.')));
      return;
    }
    await auth.logout();
    router.go('/welcome');
    messenger.showSnackBar(const SnackBar(content: Text('Cerramos tu sesión en todos tus dispositivos.')));
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
          label: const Text('Cerrar sesión en todos mis dispositivos'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: AppSpace.section),
        FilledButton.icon(
          onPressed: _busy ? null : () => context.push('/legal/delete-account'),
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Eliminar mi cuenta'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}
