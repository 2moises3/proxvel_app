import 'package:flutter/material.dart';
import '../../core/theme/app_layout.dart';
import '../../core/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

import '../../core/legal/legal_texts.dart';
import '../../core/theme/app_colors.dart';

/// Lee un documento legal (Política de Privacidad, Términos, Permisos, Fuentes…).
/// Los textos viajan dentro de la app: se leen sin internet y siempre coinciden con la versión instalada.
class LegalDocumentScreen extends StatelessWidget {
  final LegalDoc doc;

  /// Widgets extra al final (p. ej. acciones de «Mis datos»).
  final List<Widget> footer;

  const LegalDocumentScreen({super.key, required this.doc, this.footer = const []});

  /// Documento por id (ruta /legal/doc/:id). Si no existe, muestra un aviso.
  static Widget byId(String id) {
    final doc = kLegalDocs[id];
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Documento')),
        body: const Center(child: Text('No encontramos este documento.')),
      );
    }
    return LegalDocumentScreen(doc: doc);
  }

  @override
  Widget build(BuildContext context) {
    final showVersion = doc.id == 'privacidad' || doc.id == 'terminos';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          tooltip: 'Volver',
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          doc.title,
          style: AppTextStyles.sectionTitle,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 20, AppSpace.screen, 32),
          children: [
            if (showVersion) ...[
              Text(
                'Versión $kLegalVersion · Actualizada el $kLegalUpdated',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpace.related),
            ],
            for (final b in doc.blocks) _block(b),
            ...footer,
          ],
        ),
      ),
    );
  }

  Widget _block(LegalBlock b) {
    switch (b.type) {
      case 'h':
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 8),
          child: Text(
            b.text,
            style: AppTextStyles.cardTitle,
          ),
        );
      case 'ul':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in b.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 10, left: 4),
                      child: Icon(Icons.circle, size: 5, color: AppColors.accent),
                    ),
                    Expanded(
                      child: Text(item, style: AppTextStyles.bodySecondary),
                    ),
                  ],
                ),
              ),
          ],
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(b.text, style: AppTextStyles.bodySecondary),
        );
    }
  }
}
