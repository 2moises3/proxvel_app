import '../../../core/widgets/maps/visit_progress.dart';
import '../../../core/localization/l10n.dart';
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
              Expanded(
                child: Row(
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
                    Flexible(
                      child: Text(
                        context.l10n.uiAtlasDeVisitas,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            context.l10n.uiRadarGps,
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
                      context.l10n.atlasTotals(totalStamps, regionsCount),
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
            onVerify: () => finishVisit(
              context,
              visitCtrl,
              DestinationLocation.shared,
              activeVisit,
            ),
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
                          ? context.l10n.uiLlegasteAlDestino
                          : context.l10n.uiObjetivoEnEsperaDeSellado,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isInside ? AppColors.accent : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.destinationTitle(
                        pending.destinationId,
                        pending.destinationName,
                      ),
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
                tooltip: context.l10n.uiDesfijarObjetivo,
                onPressed: () => visitCtrl.clearPendingDestination(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          VisitProgress(
            controller: visitCtrl,
            location: location,
            destinationId: pending.destinationId,
            latitude: pending.latitude,
            longitude: pending.longitude,
            radius: radius,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.uiComienzaTuPasaporteDeViajes,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      context.l10n.uiVisitaDestinosTuristicosConTuApp,
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
              label: Text(
                context.l10n.uiEscanearDestinosCercanosConRadarGps,
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
          return _buildStampCard(context, stamp);
        },
      ),
    );
  }

  Widget _buildStampCard(BuildContext context, AtlasItemModel stamp) {
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
              context.destinationTitle(
                stamp.destinationId,
                stamp.destinationName,
              ),
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
