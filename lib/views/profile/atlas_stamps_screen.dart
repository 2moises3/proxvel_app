import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/visit_controller.dart';
import '../../core/localization/app_language.dart';
import '../../core/localization/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../models/visit_model.dart';
import 'widgets/profile_page_bar.dart';

class AtlasStampsScreen extends StatelessWidget {
  const AtlasStampsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VisitController>();
    final en = context.watch<AppLanguage>().languageCode == 'en';
    final visits = <AtlasItemModel>[...?controller.atlasSummary?.visits]
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, en ? 'Your stamps' : 'Tus sellos'),
      body: RefreshIndicator(
        onRefresh: controller.loadAtlas,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              en
                  ? '${visits.length} verified visits'
                  : '${visits.length} visitas verificadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (visits.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    en
                        ? 'No stamps yet. Find a nearby destination to begin.'
                        : 'Aún no tienes sellos. Busca un destino cercano para comenzar.',
                  ),
                ),
              ),
            for (final stamp in visits)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    context.destinationTitle(
                      stamp.destinationId,
                      stamp.destinationName,
                    ),
                  ),
                  subtitle: Text(
                    [
                      stamp.region,
                      '${stamp.completedAt.day}/${stamp.completedAt.month}/${stamp.completedAt.year}',
                    ].whereType<String>().join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(
                    '/destination/${Uri.encodeComponent(stamp.destinationId)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
