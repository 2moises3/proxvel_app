import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../integration/api/api_client.dart';
import '../../localization/l10n.dart';

class LocalizedReviewText extends StatefulWidget {
  const LocalizedReviewText({
    super.key,
    required this.text,
    required this.reviewId,
    this.style,
  });

  final String text;
  final String? reviewId;
  final TextStyle? style;

  @override
  State<LocalizedReviewText> createState() => _LocalizedReviewTextState();
}

class _LocalizedReviewTextState extends State<LocalizedReviewText> {
  final _translations = <String, String>{};
  String? _visibleLanguage;
  bool _busy = false;
  bool _failed = false;

  Future<void> _translate(ApiClient api, String id, String language) async {
    if (_translations.containsKey(language)) {
      setState(() => _visibleLanguage = language);
      return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final json = await api.get(
        '/reviews/${Uri.encodeComponent(id)}/translation',
        queryParams: {'lang': language},
      );
      final text = json['data']?['text'];
      if (!mounted) return;
      setState(() {
        if (text is String && text.trim().isNotEmpty) {
          _translations[language] = text;
          _visibleLanguage = language;
        } else {
          _failed = true;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = l10n.localeName;
    final translation = _visibleLanguage == language
        ? _translations[language]
        : null;
    final api = context.read<ApiClient?>();
    final id = widget.reviewId;
    if (api == null || id == null) {
      return Text(widget.text, style: widget.style);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(translation ?? widget.text, style: widget.style),
        if (translation != null)
          Text(
            l10n.automaticTranslation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (_failed)
          Text(
            l10n.translationUnavailable,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        TextButton(
          onPressed: _busy
              ? null
              : translation == null
              ? () => _translate(api, id, language)
              : () => setState(() => _visibleLanguage = null),
          child: Text(
            _busy
                ? l10n.translating
                : translation == null
                ? l10n.showTranslation
                : l10n.showOriginal,
          ),
        ),
      ],
    );
  }
}
