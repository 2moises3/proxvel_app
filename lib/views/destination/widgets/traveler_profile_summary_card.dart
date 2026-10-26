import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/traveler_profile_model.dart';

/// Bottom card showing a summary of the user's traveler profile with
/// key preferences as chips and a link to edit.
class TravelerProfileSummaryCard extends StatelessWidget {
  final TravelerProfileModel? profile;

  const TravelerProfileSummaryCard({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return _buildEmptyState(context);
    }

    final prefs = _extractPreferences(profile!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (sin acción de editar — la edición vive en el perfil)
          const Text(
            'Tu perfil de viajero (resumen)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Preference chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefs
                .map(
                  (pref) => _preferenceChip(
                    pref['icon'] as IconData,
                    pref['label'] as String,
                    pref['value'] as String,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// Estado honesto cuando el usuario no ha completado su perfil viajero.
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpace.related),
              const Expanded(
                child: Text(
                  'Perfil de viajero',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.content),
          const Text(
            'Completa tu perfil viajero para recibir explicaciones personalizadas.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/profile/preferences'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: AppSpace.related),
                  Text(
                    'Completar perfil',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _preferenceChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractPreferences(TravelerProfileModel profile) {
    return [
      {
        'icon': Icons.wb_sunny_outlined,
        'label': 'Prefiere clima',
        'value': profile.climaPreferido,
      },
      {
        'icon': Icons.groups_outlined,
        'label': 'Tolerancia a multitudes',
        'value': profile.toleranciaMultitudes,
      },
      {
        'icon': Icons.explore_outlined,
        'label': 'Tipo de interés',
        'value': profile.tipoInteres,
      },
    ];
  }
}
