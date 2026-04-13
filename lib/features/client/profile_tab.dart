import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(currentUserProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.ivory,
                      backgroundImage: u?.avatarUrl != null
                          ? CachedNetworkImageProvider(u!.avatarUrl!)
                          : null,
                      child: u?.avatarUrl == null
                          ? const Icon(Icons.person,
                              size: 36, color: AppColors.deepMaroon)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u?.name ?? 'Guest',
                              style: Theme.of(context).textTheme.titleLarge),
                          Text(u?.email ?? u?.phone ?? '',
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(u?.role.value ?? '',
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => context.push('/profile/edit'),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _tile(context, Icons.favorite_outline, 'Wishlist',
                  onTap: () => context.push('/wishlist')),
              _tile(context, Icons.notifications_outlined, 'Notifications',
                  onTap: () => context.push('/notifications')),
              _tile(context, Icons.settings_outlined, 'Settings',
                  onTap: () => context.push('/settings')),
              _tile(context, Icons.help_outline, 'Help & Support', onTap: () {}),
              const SizedBox(height: 24),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger.withOpacity(0.1),
                  foregroundColor: AppColors.danger,
                ),
                onPressed: () => ref.read(authControllerProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext c, IconData i, String t, {VoidCallback? onTap}) => Card(
        elevation: 0,
        color: Theme.of(c).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(i),
          title: Text(t),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
