import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/tourism_catalog_model.dart';

/// Datos prácticos para planear la visita. Solo muestra lo que está cargado.
class PracticalInfoCard extends StatelessWidget {
  final TourismCatalogModel? info;

  const PracticalInfoCard({super.key, this.info});

  Future<void> _openWebsite(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    final ok =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el sitio oficial.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = info;
    if (data == null) return const SizedBox.shrink();

    final rows = <Widget>[
      if (data.costLabel != null)
        _InfoItem(
          icon: Icons.payments_outlined,
          title: 'Gasto estimado de visita',
          value: data.costLabel!,
          supportingText:
              'Orientación del gasto en el lugar; no es una tarifa de entrada confirmada.',
        ),
      if (data.recommendedDuration != null)
        _InfoItem(
          icon: Icons.access_time_outlined,
          title: 'Tiempo recomendado',
          value: data.recommendedDuration!,
        ),
      if (data.howToGet != null)
        _InfoItem(
          icon: Icons.directions_outlined,
          title: 'Cómo llegar',
          value: data.howToGet!,
        ),
      if (data.visitorInfoSummary != null)
        _InfoItem(
          icon: Icons.info_outline_rounded,
          title: 'Antes de ir',
          value: data.visitorInfoSummary!,
        ),
    ];
    final website = data.officialWebsite;
    if (rows.isEmpty && website == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prepara tu visita', style: AppTextStyles.sectionTitle),
        const SizedBox(height: AppSpace.content),
        if (rows.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpace.field),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AppSpace.group,
                      color: AppColors.border,
                      thickness: 1,
                    ),
                  rows[i],
                ],
              ],
            ),
          ),
        if (website != null) ...[
          const SizedBox(height: AppSpace.content),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openWebsite(context, website),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Abrir sitio oficial'),
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String? supportingText;

  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    this.supportingText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.micro),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: AppSpace.field),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelSmall),
                const SizedBox(height: AppSpace.micro),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (supportingText != null) ...[
                  const SizedBox(height: AppSpace.related),
                  Text(supportingText!, style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
