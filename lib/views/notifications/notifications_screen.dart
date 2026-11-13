import '../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/states/content_skeleton.dart';
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
  String? _language;

  String _englishTitle(AppNotification n) => switch (n.kind) {
    'perfil_listo' => 'Your profile is ready',
    'mejor_mes' => n.title.replaceFirst(
      'Es buen momento para ir a ',
      'Now is a good time to visit ',
    ),
    'destino_nuevo' => n.title.replaceFirst(
      'Nuevo destino: ',
      'New destination: ',
    ),
    'seguridad' => switch (n.title) {
      'Cambiaste tu contraseña' => 'You changed your password',
      'Restableciste tu contraseña' => 'You reset your password',
      _ => 'Your password was reset',
    },
    _ => n.title,
  };

  String _englishBody(AppNotification n) => switch (n.kind) {
    'perfil_listo' =>
      'See recommendations matched to your preferences in For you.',
    'mejor_mes' =>
      'This is your best month to visit. Open the destination for details.',
    'destino_nuevo' =>
      'Explore this destination and find details for your visit.',
    'seguridad' => switch (n.title) {
      'Cambiaste tu contraseña' =>
        'We signed you out of your other sessions. Reset your password immediately if this was not you.',
      'Restableciste tu contraseña' =>
        'We signed you out of all sessions. Contact support immediately if this was not you.',
      _ =>
        'A PROXVEL administrator reset your password. Choose your own password under Profile → Change password.',
    },
    _ => n.body,
  };
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = context.l10n.localeName;
    if (_language == language) return;
    _language = language;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationsController>().load();
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
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.notifications,
          style: AppTextStyles.sectionTitle,
        ),
        actions: [
          if (ctrl.hasUnread)
            TextButton(
              onPressed: ctrl.markAllRead,
              child: Text(context.l10n.markAllRead),
            ),
        ],
      ),
      body: Column(
        children: [
          if (ctrl.isLoading && ctrl.items.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
          if (ctrl.error != null && ctrl.items.isNotEmpty)
            ListTile(
              title: Text(
                ctrl.connectionUnavailable
                    ? context.l10n.connectionUnavailable
                    : context.errorText(ctrl.error!),
              ),
              trailing: TextButton(
                onPressed: ctrl.load,
                child: Text(context.l10n.retry),
              ),
            ),
          Expanded(child: _body(ctrl)),
        ],
      ),
    );
  }

  Widget _body(NotificationsController ctrl) {
    if (ctrl.isLoading && ctrl.items.isEmpty) {
      return const SingleChildScrollView(
        child: ContentSkeleton(SkeletonLayout.notifications),
      );
    }
    if (ctrl.error != null && ctrl.items.isEmpty) {
      return ProxvelEmptyState(
        icon: Icons.wifi_off_rounded,
        title: context.l10n.uiNoPudimosCargarTusAvisos,
        subtitle: ctrl.connectionUnavailable
            ? context.l10n.connectionUnavailable
            : context.errorText(ctrl.error!),
        actionLabel: context.l10n.retry,
        onAction: ctrl.load,
      );
    }
    if (ctrl.items.isEmpty) {
      return ProxvelEmptyState(
        icon: Icons.notifications_none_rounded,
        title: context.l10n.allCaughtUp,
        subtitle: context.l10n.uiAquiVerasLosAnunciosDeProxvel,
      );
    }

    final items = [...ctrl.items]
      ..sort((a, b) {
        final byPriority = _priority(a).compareTo(_priority(b));
        return byPriority != 0
            ? byPriority
            : b.createdAt.compareTo(a.createdAt);
      });
    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: ctrl.load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: 1, indent: 76, color: AppColors.divider),
        itemBuilder: (context, i) => _tile(ctrl, items[i]),
      ),
    );
  }

  int _priority(AppNotification notification) {
    if (!notification.isRead && notification.kind == 'seguridad') return 0;
    if (!notification.isRead &&
        notification.ctaText?.trim().isNotEmpty == true) {
      return 1;
    }
    return 2;
  }

  Widget _tile(NotificationsController ctrl, AppNotification n) {
    final english = context.l10n.localeName == 'en';
    final title = english ? _englishTitle(n) : n.title;
    final body = english ? _englishBody(n) : n.body;
    final unread = !n.isRead;
    return InkWell(
      onTap: () => _open(ctrl, n),
      child: Container(
        color: unread
            ? AppColors.accentSoft.withValues(alpha: 0.45)
            : Colors.transparent,
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
                  if (_priority(n) < 2)
                    Text(
                      context.l10n.actionRequired,
                      style: AppTextStyles.caption,
                    ),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body2,
                    ),
                  ],
                  const SizedBox(height: 6),
                  if (english &&
                      n.type == 'announcement' &&
                      n.contentLanguage != 'en')
                    Text(
                      context.l10n.spanishOriginal,
                      style: AppTextStyles.body2,
                    ),
                  Text(
                    n.timeAgo(english: english),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
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
