import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../controllers/notifications_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/states/proxvel_empty_state.dart';
import '../../models/notification_model.dart';

/// Centro de notificaciones: anuncios del dashboard y avisos personales en una sola
/// lista, del más reciente al más antiguo. Tocar uno lo marca como leído y abre su pantalla.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsController>().load();
    });
  }

  IconData _iconFor(AppNotification n) {
    switch (n.kind) {
      case 'mejor_mes':
        return Icons.event_available_rounded;
      case 'perfil_listo':
        return Icons.auto_awesome_rounded;
      case 'destino_nuevo':
        return Icons.place_rounded;
      case 'seguridad':
        return Icons.lock_outline_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Future<void> _open(NotificationsController ctrl, AppNotification n) async {
    ctrl.markRead(n);
    final route = n.route;
    if (route == null || route.isEmpty) return;
    if (route.startsWith('https://')) {
      final uri = Uri.tryParse(route);
      if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    // Las pestañas principales se alcanzan con go; el resto se apila para poder volver.
    if (route == '/main' || route.startsWith('/main?')) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<NotificationsController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: AppTextStyles.sectionTitle,
        ),
        actions: [
          if (ctrl.hasUnread)
            TextButton(
              onPressed: ctrl.markAllRead,
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: _body(ctrl),
    );
  }

  Widget _body(NotificationsController ctrl) {
    if (ctrl.isLoading && ctrl.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (ctrl.error != null && ctrl.items.isEmpty) {
      return ProxvelEmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'No pudimos cargar tus avisos',
        subtitle: ctrl.error!,
        actionLabel: 'Reintentar',
        onAction: ctrl.load,
      );
    }
    if (ctrl.items.isEmpty) {
      return const ProxvelEmptyState(
        icon: Icons.notifications_none_rounded,
        title: 'Todo al día',
        subtitle:
            'Aquí verás los anuncios de PROXVEL y avisos hechos para ti, como cuándo es el mejor mes para ir a tus favoritos.',
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: ctrl.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: ctrl.items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 76, color: AppColors.divider),
        itemBuilder: (context, i) => _tile(ctrl, ctrl.items[i]),
      ),
    );
  }

  Widget _tile(NotificationsController ctrl, AppNotification n) {
    final unread = !n.isRead;
    return InkWell(
      onTap: () => _open(ctrl, n),
      child: Container(
        color: unread ? AppColors.accentSoft.withValues(alpha: 0.45) : Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(_iconFor(n), color: AppColors.accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    n.timeAgo(),
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (unread)
              Container(
                margin: const EdgeInsets.only(left: 10, top: 6),
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
