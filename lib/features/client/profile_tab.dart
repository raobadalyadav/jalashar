import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/theme/app_theme.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.ivory,
                    child: Icon(Icons.person, size: 36, color: AppColors.deepMaroon),
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
                        Text('Role: ${u?.role.value ?? ''}'),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _tile(context, Icons.language, 'Language', trailing: DropdownButton<Locale>(
              value: context.locale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                DropdownMenuItem(value: Locale('gu'), child: Text('ગુજરાતી')),
                DropdownMenuItem(value: Locale('mr'), child: Text('मराठी')),
                DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
              ],
              onChanged: (l) { if (l != null) context.setLocale(l); },
            )),
            _tile(context, Icons.favorite_outline, 'Wishlist'),
            _tile(context, Icons.receipt_long_outlined, 'Payment History'),
            _tile(context, Icons.notifications_outlined, 'Notifications'),
            _tile(context, Icons.privacy_tip_outlined, 'Privacy & Security'),
            _tile(context, Icons.help_outline, 'Help & Support'),
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
    );
  }

  Widget _tile(BuildContext c, IconData i, String t, {Widget? trailing}) => Card(
        elevation: 0,
        color: Theme.of(c).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(i),
          title: Text(t),
          trailing: trailing ?? const Icon(Icons.chevron_right),
          onTap: () {},
        ),
      );
}
