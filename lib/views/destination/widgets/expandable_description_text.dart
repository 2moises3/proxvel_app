import 'package:flutter/material.dart';
import '../../../core/theme/app_layout.dart';
import '../../../core/theme/app_text_styles.dart';

class ExpandableDescriptionText extends StatefulWidget {
  final String text;
  final int maxLines;
  const ExpandableDescriptionText({
    super.key,
    required this.text,
    this.maxLines = 4,
  });
  @override
  State<ExpandableDescriptionText> createState() =>
      _ExpandableDescriptionTextState();
}

class _ExpandableDescriptionTextState extends State<ExpandableDescriptionText> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final style = DefaultTextStyle.of(
        context,
      ).style.merge(AppTextStyles.bodySecondary);
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: style),
        maxLines: widget.maxLines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: size.maxWidth);
      final overflows = painter.didExceedMaxLines;
      painter.dispose();
      final text = Text(
        widget.text,
        maxLines: _expanded ? null : widget.maxLines,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        style: AppTextStyles.bodySecondary,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (MediaQuery.disableAnimationsOf(context))
            text
          else
            AnimatedSize(
              duration: AppMotion.standard,
              curve: AppMotion.curve,
              alignment: Alignment.topCenter,
              child: text,
            ),
          if (overflows)
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              label: Text(_expanded ? 'Mostrar menos' : 'Leer descripción'),
              iconAlignment: IconAlignment.end,
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 18,
              ),
            ),
        ],
      );
    },
  );
}
