import '../../core/localization/l10n.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/localization/app_language.dart';
import '../../controllers/visit_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_layout.dart';
import '../../core/widgets/maps/destination_location.dart';
import 'widgets/profile_page_bar.dart';

class AtlasScreen extends StatefulWidget {
  const AtlasScreen({super.key});

  @override
  State<AtlasScreen> createState() => _AtlasScreenState();
}

class _AtlasScreenState extends State<AtlasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VisitController>().initVisitState();
      DestinationLocation.shared.locate(requestPermission: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visit = context.watch<VisitController>();
    final en = context.watch<AppLanguage>().languageCode == 'en';
    final active = visit.activeVisit;
    final pending = visit.pendingDestination;
    final stamps = visit.atlasSummary?.visits ?? [];
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: profilePageBar(context, context.l10n.visitAtlas),
      body: RefreshIndicator(
        onRefresh: visit.initVisitState,
        child: ListView(
          padding: EdgeInsets.only(
            top: AppSpace.section,
            bottom: 32 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            if (visit.isLoading)
              const LinearProgressIndicator(color: AppColors.accent),
            if (visit.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen,
                  0,
                  AppSpace.screen,
                  AppSpace.section,
                ),
                child: Text(
                  context.errorText(visit.error!),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    en ? 'Your travel passport' : 'Tu pasaporte de viajes',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    en
                        ? 'Discover nearby places, follow your visit and keep every stamp.'
                        : 'Descubre lugares cercanos, sigue tu visita y guarda cada sello.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  if (active?.isInProgress == true || pending != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active != null
                                  ? (en
                                        ? 'VISIT IN PROGRESS'
                                        : 'VISITA EN CURSO')
                                  : (en
                                        ? 'SELECTED DESTINATION'
                                        : 'DESTINO ELEGIDO'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              context.destinationTitle(
                                active?.destinationId ?? pending!.destinationId,
                                active?.destinationName ??
                                    pending?.destinationName ??
                                    '',
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (active != null) ...[
                              const SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: active.progress,
                                minHeight: 7,
                                color: AppColors.accent,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                active.progress >= 1
                                    ? (en
                                          ? 'Ready to stamp'
                                          : 'Lista para sellar')
                                    : (en
                                          ? '${active.remainingMinutes} min remaining'
                                          : '${active.remainingMinutes} min restantes'),
                              ),
                            ],
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: () =>
                                  context.push('/profile/atlas/visit'),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                en ? 'Continue visit' : 'Continuar visita',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(
                        Icons.near_me_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        en ? 'Places near you' : 'Lugares cerca de ti',
                      ),
                      subtitle: Text(
                        en
                            ? 'Closest match and two alternatives'
                            : 'El más cercano y dos alternativas',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/profile/atlas/nearby'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _AtlasStat(
                          '${visit.atlasSummary?.totalVerifiedVisits ?? 0}',
                          en ? 'Stamps' : 'Sellos',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AtlasStat(
                          '${visit.atlasSummary?.regionsVisited ?? 0}',
                          en ? 'Regions' : 'Regiones',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          en ? 'Recent stamps' : 'Sellos recientes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/profile/atlas/stamps'),
                        child: Text(en ? 'View all' : 'Ver todos'),
                      ),
                    ],
                  ),
                  if (stamps.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          en
                              ? 'Your first stamp will appear after a verified visit.'
                              : 'Tu primer sello aparecerá tras una visita verificada.',
                        ),
                      ),
                    ),
                  for (final stamp in stamps.take(3))
                    Card(
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
                        subtitle: Text(stamp.region ?? ''),
                        onTap: () => context.push(
                          '/destination/${Uri.encodeComponent(stamp.destinationId)}',
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

class _AtlasStat extends StatelessWidget {
  const _AtlasStat(this.value, this.label);
  final String value, label;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}
