import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../app/theme.dart';
import '../../models/content.dart';
import '../../widgets/symbol_badge.dart';

/// Renders the full body of a [Content] using the right widget for its
/// declared `format`. Markdown and HTML get their dedicated renderers;
/// `text` falls through to `SelectableText`.
class ContentDetailScreen extends StatelessWidget {
  final Content content;

  const ContentDetailScreen({Key? key, required this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          content.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _LevelBadge(level: content.requiredLevel, label: content.levelDisplay),
                if (content.symbolType != null)
                  SymbolBadge(
                    symbolType: content.symbolType,
                    requiredLevel: content.requiredLevel,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            _renderBody(context),
          ],
        ),
      ),
    );
  }

  Widget _renderBody(BuildContext context) {
    switch (content.format.toLowerCase()) {
      case 'markdown':
        return MarkdownBody(
          data: content.body,
          selectable: true,
          shrinkWrap: true,
        );
      case 'html':
        return Html(
          data: content.body,
          style: {
            "body": Style(margin: Margins.zero),
          },
        );
      default:
        return SelectableText(
          content.body,
          style: AppTypography.bodyLarge,
        );
    }
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final String label;

  const _LevelBadge({required this.level, required this.label});

  Color _color() {
    if (level <= 1) return Colors.grey;
    if (level <= 3) return Colors.blue;
    if (level <= 5) return Colors.purple;
    if (level <= 7) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: _color(),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }
}
