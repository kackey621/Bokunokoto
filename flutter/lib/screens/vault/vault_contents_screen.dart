import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/content_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/content_card.dart';
import 'content_detail_screen.dart';

class VaultContentsScreen extends ConsumerWidget {
  final String vaultId;

  const VaultContentsScreen({Key? key, required this.vaultId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentsAsync = ref.watch(contentProvider(vaultId));
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vault Contents'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(contentProvider(vaultId)).future,
        child: contentsAsync.when(
          data: (contents) {
            if (contents.isEmpty) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                    Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'No content available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: contents.length,
              itemBuilder: (context, index) {
                final content = contents[index];
                return Column(
                  children: [
                    ContentCard(
                      content: content,
                      isProfileRequired: authState.bkUser != null &&
                          authState.bkUser!.mode == BKMode.viewer,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ContentDetailScreen(content: content),
                          ),
                        );
                      },
                    ),
                    if (index < contents.length - 1)
                      const SizedBox(height: Spacing.md),
                  ],
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: Spacing.md),
                Text(
                  'Failed to load contents',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: Spacing.md),
                ElevatedButton(
                  onPressed: () => ref.refresh(contentProvider(vaultId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
