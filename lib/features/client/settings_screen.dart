import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';

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
          _Section(title: 'Account', children: [
            _tile(Icons.edit_outlined, 'Edit profile', onTap: () => context.push('/profile/edit')),
            _tile(Icons.favorite_outline, 'Wishlist', onTap: () => context.push('/wishlist')),
            _tile(Icons.card_giftcard, 'Refer & Earn', onTap: () => context.push('/referral')),
          ]),
          _Section(title: 'Preferences', children: [
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
                  await ref.read(userRepoProvider).updateProfile(locale: l.languageCode);
                  ref.invalidate(currentUserProvider);
                },
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('Push Notifications'),
              value: _notifications,
              onChanged: _setNotifications,
            ),
          ]),
          _Section(title: 'Support', children: [
            _tile(Icons.help_outline, 'FAQ', onTap: () => context.push('/faq')),
            _tile(Icons.support_agent, 'Contact Support', onTap: () => context.push('/support')),
            _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
                onTap: () => context.push('/privacy-policy')),
            _tile(Icons.description_outlined, 'Terms of Service',
                onTap: () => context.push('/terms')),
          ]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                backgroundColor: AppColors.danger.withOpacity(0.1),
                foregroundColor: AppColors.danger,
              ),
              onPressed: () async {
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) context.go('/auth/sign-in');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _tile(IconData i, String t, {VoidCallback? onTap}) => ListTile(
        leading: Icon(i),
        title: Text(t),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.slate)),
        ),
        ...children,
      ],
    );
  }
}
