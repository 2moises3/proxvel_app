import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../controllers/visit_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/widgets/cards/liquid_progress_visit_card.dart';
import '../../../core/widgets/maps/destination_location.dart';
import '../../../models/visit_model.dart';
import 'destination_radar_sheet.dart';

class AtlasPassportSection extends StatelessWidget {
  const AtlasPassportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final visitCtrl = context.watch<VisitController>();
    final activeVisit = visitCtrl.activeVisit;
    final pending = visitCtrl.pendingDestination;
    final atlas = visitCtrl.atlasSummary;
    final verifiedVisits = atlas?.visits ?? [];
    final totalStamps = atlas?.totalVerifiedVisits ?? 0;
    final regionsCount = atlas?.regionsVisited ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera de la sección
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Atlas de Visitas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => DestinationRadarSheet.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Radar GPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      '$totalStamps sellos • $regionsCount regiones',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // ── 1. Si hay una visita en progreso: Card Líquida con agua subiendo ──
        if (activeVisit != null && activeVisit.isInProgress) ...[
          LiquidProgressVisitCard(
            visit: activeVisit,
            isVerifying: visitCtrl.isActionLoading,
            onVerify: () async {
              final loc = DestinationLocation.shared;
              await loc.locate(requestPermission: true);
              final position = loc.position;
              if (position == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        loc.error ??
                            'Activa tu ubicación para sellar la visita.',
                      ),
                    ),
                  );
                }
                return;
              }
              final ok = await visitCtrl.verifyActiveVisit(
                latitude: position.latitude,
                longitude: position.longitude,
              );
              if (context.mounted && ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '🎉 ¡Tu visita ha sido sellada con éxito en tu Atlas!',
                    ),
                    backgroundColor: AppColors.accent,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      visitCtrl.error ?? 'No pudimos sellar la visita.',
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ]
        // ── 2. Si no hay visita en progreso pero sí un objetivo en espera ──
        else if (pending != null) ...[
          AnimatedBuilder(
            animation: DestinationLocation.shared,
            builder: (context, _) =>
                _buildPendingDestinationCard(context, visitCtrl, pending),
          ),
          const SizedBox(height: 12),
        ],

        // ── 3. Sellos completados o Empty State ──
        if (verifiedVisits.isEmpty &&
            (activeVisit == null || !activeVisit.isInProgress) &&
            pending == null)
          _buildEmptyAtlas(context)
        else if (verifiedVisits.isNotEmpty)
          _buildStampsGrid(verifiedVisits),
      ],
    );
  }

  Widget _buildPendingDestinationCard(
    BuildContext context,
    VisitController visitCtrl,
    PendingSealDestination pending,
  ) {
    final location = DestinationLocation.shared;
    final dist = location.distance(pending.latitude, pending.longitude);
    final radius = pending.geofenceRadiusMeters;
    final isInside = dist != null && dist <= radius;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpace.screen,
        vertical: 4,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isInside
              ? AppColors.accent.withValues(alpha: 0.6)
              : AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isInside ? AppColors.accent : AppColors.primary).withValues(
              alpha: 0.08,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isInside ? AppColors.accent : AppColors.primary)
                      .withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInside ? Icons.place_rounded : Icons.track_changes_rounded,
                  size: 20,
                  color: isInside ? AppColors.accent : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isInside
                          ? '🎯 ¡LLEGASTE AL DESTINO!'
                          : '🎯 OBJETIVO EN ESPERA DE SELLADO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isInside ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pending.destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                tooltip: 'Desfijar objetivo',
                onPressed: () => visitCtrl.clearPendingDestination(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isInside
                  ? AppColors.accent.withValues(alpha: 0.08)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 15,
                  color: isInside ? AppColors.accent : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dist != null
                        ? isInside
                              ? 'Estás a ${dist.round()} m (radio permitido: $radius m)'
                              : 'Estás a ${dist.round()} m. Acércate a menos de $radius m para iniciar el conteo.'
                        : 'Activa tu ubicación para calcular la distancia.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isInside
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isInside
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isInside
                ? ElevatedButton.icon(
                    onPressed: visitCtrl.isActionLoading
                        ? null
                        : () async {
                            await location.locate(requestPermission: true);
                            final position = location.position;
                            if (position == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      location.error ??
                                          'Activa tu ubicación para iniciar la visita.',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            final ok = await visitCtrl.startCheckIn(
                              destinationId: pending.destinationId,
                              latitude: position.latitude,
                              longitude: position.longitude,
                            );
                            if (context.mounted && ok) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '⏱️ ¡Conteo iniciado! La card de agua se irá llenando.',
                                  ),
                                  backgroundColor: AppColors.accent,
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    visitCtrl.error ??
                                        'No pudimos iniciar la visita.',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: visitCtrl.isActionLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text(
                      'Iniciar conteo de estancia',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: () => DestinationRadarSheet.show(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(Icons.radar_rounded, size: 18),
                    label: const Text(
                      'Abrir Radar GPS',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAtlas(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpace.screen,
        vertical: 6,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 28,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comienza tu pasaporte de viajes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Visita destinos turísticos con tu app abierta para desbloquear sellos oficiales en tu Atlas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => DestinationRadarSheet.show(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.radar_rounded, size: 18),
              label: const Text(
                'Escanear destinos cercanos con Radar GPS',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStampsGrid(List<AtlasItemModel> stamps) {
    return SizedBox(
      height: 140,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: stamps.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stamp = stamps[index];
          return _buildStampCard(stamp);
        },
      ),
    );
  }

  Widget _buildStampCard(AtlasItemModel stamp) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ),
                if (stamp.region != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      stamp.region!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              stamp.destinationName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 11,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Text(
                  '${stamp.dwellMinutes} min',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Verificado',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
