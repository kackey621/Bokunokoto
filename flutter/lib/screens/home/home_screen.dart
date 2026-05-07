import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bokunokoto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Home',
              style: AppTypography.h2,
            ),
            const SizedBox(height: Spacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to Bokunokoto',
                      style: AppTypography.h3,
                    ),
                    const SizedBox(height: Spacing.sm),
                    Text(
                      'Connect with vaults and explore shared content.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.goNamed('qr-scan'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR Code'),
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSlugPrompt(context),
                        icon: const Icon(Icons.qr_code),
                        label: const Text('Show Access QR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Recent Activity',
              style: AppTypography.h3,
            ),
            const SizedBox(height: Spacing.md),
            // TODO: Load recent activity from API
            Center(
              child: Text(
                'No activity yet',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSlugPrompt(BuildContext context) async {
    final controller = TextEditingController();
    final slug = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Access Link Slug'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. my-share-link',
            helperText: 'Enter the slug for the link to display',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Show QR'),
          ),
        ],
      ),
    );
    if (slug == null || slug.isEmpty) return;
    if (!context.mounted) return;
    context.goNamed('qr-generate', pathParameters: {'slug': slug});
  }
}
