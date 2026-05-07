import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/content.dart';

class ContentCard extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;
  final bool isProfileRequired;

  const ContentCard({
    Key? key,
    required this.content,
    required this.onTap,
    required this.isProfileRequired,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: content.requiresProfile && isProfileRequired ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          content.title,
                          style: AppTypography.h3,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(content.requiredLevel),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.levelDisplay,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Icon(
                    _getFormatIcon(content.format),
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              Text(
                content.body.replaceAll(RegExp(r'<[^>]*>'), '').length > 100
                    ? content.body.replaceAll(RegExp(r'<[^>]*>'), '').substring(0, 100) + '...'
                    : content.body.replaceAll(RegExp(r'<[^>]*>'), ''),
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: Spacing.md),
              if (content.requiresLogin)
                Row(
                  children: [
                    Icon(Icons.lock_outline, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Login required',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                )
              else if (content.requiresProfile && isProfileRequired)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Profile required',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, size: 16, color: Colors.green[700]),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      'Accessible',
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFormatIcon(String format) {
    switch (format.toLowerCase()) {
      case 'markdown':
        return Icons.description;
      case 'html':
        return Icons.language;
      case 'text':
        return Icons.article;
      default:
        return Icons.file_present;
    }
  }

  Color _getLevelColor(int level) {
    if (level <= 1) return Colors.grey;
    if (level <= 3) return Colors.blue;
    if (level <= 5) return Colors.purple;
    if (level <= 7) return Colors.orange;
    return Colors.red;
  }
}
