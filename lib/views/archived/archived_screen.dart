import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/archive_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../core/widgets/images/adaptive_destination_image.dart';

class ArchivedScreen extends StatefulWidget {
  const ArchivedScreen({super.key});

  @override
  State<ArchivedScreen> createState() => _ArchivedScreenState();
}

class _ArchivedScreenState extends State<ArchivedScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArchiveController>().loadArchives();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Volver',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Text(
          'Archivados',
          style: AppTextStyles.sectionTitle,
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ArchiveController>(
        builder: (context, arcCtrl, _) {
          if (arcCtrl.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (arcCtrl.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: AppSpace.field),
                    Text(
                      'No se pudieron cargar los archivados',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpace.related),
                    Text(
                      arcCtrl.error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                    ElevatedButton(
                      onPressed: arcCtrl.loadArchives,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (arcCtrl.archives.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpace.screen),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.archive_outlined,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                    Text(
                      'Sin archivos',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpace.content),
                    Text(
                      'Aquí aparecerán los destinos que hayas decidido ocultar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: arcCtrl.loadArchives,
            color: AppColors.primary,
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: arcCtrl.archives.length,
              itemBuilder: (context, index) {
                final arc = arcCtrl.archives[index];
                final location = [arc.city, arc.region]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join(', ');
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: AppColors.surface,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        context.push('/destination/${arc.destinationId}'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 84,
                              height: 84,
                              child: AdaptiveDestinationImage(
                                imagePath: arc.coverImageUrl ?? '',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpace.content),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  arc.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.cardTitle,
                                ),
                                if (location.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    location,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar de archivados',
                            constraints: const BoxConstraints(
                              minWidth: 44,
                              minHeight: 44,
                            ),
                            onPressed: () =>
                                arcCtrl.toggleArchive(arc.destinationId),
                            icon: const Icon(Icons.unarchive_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
