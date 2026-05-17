import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    if (authState.firebaseUser?.photoURL != null)
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          authState.firebaseUser!.photoURL!,
                        ),
                      )
                    else
                      const CircleAvatar(
                        radius: 40,
                        child: Icon(Icons.person),
                      ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authState.firebaseUser?.displayName ?? 'User',
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: Spacing.sm),
                          Text(
                            authState.firebaseUser?.email ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Account Settings',
              style: AppTypography.h3,
            ),
            const SizedBox(height: Spacing.md),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: const Text('Bank Account'),
              subtitle: const Text('Add or update bank account details'),
              onTap: () => context.goNamed('profile-bank'),
            ),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
