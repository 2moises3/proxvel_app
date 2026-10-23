import 'package:provider/provider.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../controllers/profile_controller.dart';
import '../../../models/traveler_types.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class ProfileSummaryCard extends StatefulWidget {
  final String userName;
  const ProfileSummaryCard({super.key, required this.userName});

  @override
  State<ProfileSummaryCard> createState() => _ProfileSummaryCardState();
}

class _ProfileSummaryCardState extends State<ProfileSummaryCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>().profile;
    final style = travelerTypes[profile?.perfilTuristico];
    final String initial = widget.userName.isNotEmpty
        ? widget.userName[0].toUpperCase()
        : 'M';

    return AnimatedContainer(
      duration: AppMotion.duration(context),
      curve: AppMotion.curve,
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          children: [
            // ── Header (Always Visible) ──
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left Section
                    Expanded(
                      flex: 5,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft.withValues(alpha: 0.3),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.explore_outlined,
                              size: 24,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: AppSpace.content),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Viajero',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: AppSpace.micro),
                                  Text(
                                    'PROXVEL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider
                    Container(
                      width: 1,
                      color: AppColors.border,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    // Right Section
                    Expanded(
                      flex: 6,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: AppTextStyles.cardTitleOnDark,
                              ),
                            ),
                            const SizedBox(width: AppSpace.content),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Tu perfil',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isExpanded ? 'Ocultar' : 'Ver detalles',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              _isExpanded
                                  ? Icons.arrow_upward
                                  : Icons.arrow_forward,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded Content ──
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpace.field),
                    Text(
                      style == null
                          ? 'Elige tu estilo de viajero para activar las recomendaciones.'
                          : 'Estilo $style. El orden considera tus intereses, clima y tolerancia para el mes elegido.',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: AppSpace.card),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            context.push('/profile/preferences');
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 16,
                                  color: AppColors.textPrimary,
                                ),
                                SizedBox(width: AppSpace.related),
                                Text(
                                  'Editar preferencias',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
