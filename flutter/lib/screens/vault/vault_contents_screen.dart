import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';

class VaultContentsScreen extends ConsumerWidget {
  final String vaultId;

  const VaultContentsScreen({Key? key, required this.vaultId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vault: $vaultId'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contents',
              style: AppTypography.h2,
            ),
            const SizedBox(height: Spacing.lg),
            // TODO: Load and display contents from API
            Center(
              child: Text(
                'Loading contents...',
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
