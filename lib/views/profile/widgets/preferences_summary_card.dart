import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/traveler_types.dart';
import '../../../models/traveler_profile_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common/app_icon.dart';

class PreferencesSummaryCard extends StatelessWidget {
  const PreferencesSummaryCard({super.key, required this.profile});
  final TravelerProfileModel profile;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/profile/preferences'),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const AppIcon(
                AppIcons.sparkles,
                size: 28,
                color: AppColors.discovery,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tu forma de viajar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      travelerTypes[profile.perfilTuristico] ??
                          'Completa tus preferencias',
                      style: const TextStyle(
                        color: AppColors.discovery,
                        fontSize: 14,
                      ),
                    ),
                    if (profile.intereses.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        profile.intereses.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const AppIcon(
                AppIcons.chevronRight,
                size: 19,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
