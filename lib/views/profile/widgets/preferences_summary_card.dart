import '../../../models/traveler_types.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/traveler_profile_model.dart';

/// Resumen de las preferencias del viajero (presupuesto, días, clima, etc.)
/// como chips. Solo muestra datos reales del perfil.
class PreferencesSummaryCard extends StatelessWidget {
  final TravelerProfileModel profile;

  const PreferencesSummaryCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              travelerTypes[profile.perfilTuristico] ??
                  'Elige tu estilo de viajero',
              style: AppTextStyles.cardTitle,
            ),
            const SizedBox(height: AppSpace.field),
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tu forma de viajar',
                  style: AppTextStyles.cardTitle,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PrefChip(
                  icon: Icons.payments_outlined,
                  label: profile.presupuesto,
                ),
                _PrefChip(
                  icon: Icons.calendar_today_outlined,
                  label: profile.diasViaje >= 7
                      ? '7+ días'
                      : '${profile.diasViaje} días',
                ),
                _PrefChip(
                  icon: Icons.wb_sunny_outlined,
                  label: profile.climaPreferido,
                ),
                _PrefChip(
                  icon: Icons.groups_outlined,
                  label: 'Multitud: ${profile.toleranciaMultitudes}',
                ),
                ...profile.intereses
                    .take(4)
                    .map(
                      (i) =>
                          _PrefChip(icon: Icons.local_offer_outlined, label: i),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PrefChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PrefChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: AppTextStyles.smallLabel)),
        ],
      ),
    );
  }
}
