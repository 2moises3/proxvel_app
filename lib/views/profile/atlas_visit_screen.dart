import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/visit_controller.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/maps/destination_location.dart';
import '../../core/widgets/maps/visit_progress.dart';
import 'widgets/profile_page_bar.dart';

class AtlasVisitScreen extends StatefulWidget {
  const AtlasVisitScreen({super.key});
  @override
  State<AtlasVisitScreen> createState() => _AtlasVisitScreenState();
}

class _AtlasVisitScreenState extends State<AtlasVisitScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final controller = context.read<VisitController>();
        controller.checkActiveVisit();
        if (controller.pendingDestination != null &&
            DestinationLocation.shared.position == null) {
          DestinationLocation.shared.locate(requestPermission: false);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (mounted && state == AppLifecycleState.resumed) {
      context.read<VisitController>().checkActiveVisit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VisitController>();
    final location = DestinationLocation.shared;
    final en = context.watch<AppLanguage>().languageCode == 'en';
    final active = controller.activeVisit;
    final pending = controller.pendingDestination;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, en ? 'Your visit' : 'Tu visita'),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (active?.isInProgress == true) ...[
            Text(
              context.destinationTitle(
                active!.destinationId,
                active.destinationName ?? active.destinationId,
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      en ? 'Visit progress' : 'Progreso de la visita',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(active.progress * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                    ),
                    Text(
                      en
                          ? '${active.dwellMinutes.clamp(0, active.minDwellMinutes)} of ${active.minDwellMinutes} minutes completed'
                          : '${active.dwellMinutes.clamp(0, active.minDwellMinutes)} de ${active.minDwellMinutes} minutos cumplidos',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      active.progress >= 1
                          ? (en ? 'Time completed' : 'Tiempo cumplido')
                          : (en
                                ? '${active.remainingMinutes} minutes remaining'
                                : '${active.remainingMinutes} minutos restantes'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: active.progress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.accent,
                      semanticsLabel: en
                          ? 'Visit progress'
                          : 'Progreso de la visita',
                      semanticsValue: '${(active.progress * 100).round()}%',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      en
                          ? 'The server verifies your stay. You can leave this screen and return later.'
                          : 'El servidor verifica tu permanencia. Puedes salir de esta pantalla y volver después.',
                    ),
                    if (active.progress >= 1) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: controller.isActionLoading
                            ? null
                            : () => finishVisit(
                                context,
                                controller,
                                location,
                                active,
                              ),
                        child: Text(en ? 'Stamp visit' : 'Sellar visita'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else if (pending != null) ...[
            Text(
              context.destinationTitle(
                pending.destinationId,
                pending.destinationName,
              ),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      en
                          ? 'Approach within ${pending.geofenceRadiusMeters} m. Stay for ${pending.minDwellMinutes} min to earn a stamp.'
                          : 'Acércate a ${pending.geofenceRadiusMeters} m. Permanece ${pending.minDwellMinutes} min para obtener el sello.',
                    ),
                    const SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: location,
                      builder: (context, _) => VisitProgress(
                        controller: controller,
                        location: location,
                        destinationId: pending.destinationId,
                        latitude: pending.latitude,
                        longitude: pending.longitude,
                        radius: pending.geofenceRadiusMeters,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.clearPendingDestination();
                        context.go('/profile/atlas');
                      },
                      child: Text(en ? 'Remove destination' : 'Quitar destino'),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      en
                          ? 'No visit in progress.'
                          : 'No hay una visita en curso.',
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go('/profile/atlas/nearby'),
                      child: Text(
                        en ? 'Find a nearby place' : 'Buscar un lugar cercano',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (controller.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                context.errorText(controller.error!),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}
