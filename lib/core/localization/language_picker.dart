import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';
import 'l10n.dart';

Future<void> showLanguagePicker(BuildContext context) async {
  final language = context.read<AppLanguage>();
  final selected = await showModalBottomSheet<LanguageChoice>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              context.l10n.language,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final choice in LanguageChoice.values)
            ListTile(
              title: Text(switch (choice) {
                LanguageChoice.system => context.l10n.deviceLanguage,
                LanguageChoice.es => 'Español',
                LanguageChoice.en => 'English',
              }),
              selected: language.choice == choice,
              trailing: language.choice == choice
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, choice),
            ),
        ],
      ),
    ),
  );
  if (selected != null && context.mounted) await language.select(selected);
}
