import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notifications = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _notifications = prefs.getBool('notifications') ?? true);
  }

  Future<void> _setNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', v);
    setState(() => _notifications = v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit profile'),
            onTap: () => context.push('/profile/edit'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: DropdownButton<Locale>(
              value: context.locale,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English')),
                DropdownMenuItem(value: Locale('hi'), child: Text('हिन्दी')),
                DropdownMenuItem(value: Locale('gu'), child: Text('ગુજરાતી')),
                DropdownMenuItem(value: Locale('mr'), child: Text('मराठी')),
                DropdownMenuItem(value: Locale('ta'), child: Text('தமிழ்')),
              ],
              onChanged: (l) async {
                if (l == null) return;
                await context.setLocale(l);
                await ref
                    .read(userRepoProvider)
                    .updateProfile(locale: l.languageCode);
                ref.invalidate(currentUserProvider);
              },
            ),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            value: _notifications,
            onChanged: _setNotifications,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.favorite_outline),
            title: const Text('Wishlist'),
            onTap: () => context.push('/wishlist'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('All Notifications'),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of Service'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign out', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/auth/sign-in');
            },
          ),
        ],
      ),
    );
  }
}
