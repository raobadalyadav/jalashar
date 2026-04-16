import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/providers/theme_provider.dart';
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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Account ──────────────────────────────────────────────────────
          _Section(title: 'Account', children: [
            _Tile(
              icon: Icons.person_outline_rounded,
              label: 'Edit Profile',
              color: AppColors.violet,
              onTap: () => context.push('/profile/edit'),
            ),
            _Tile(
              icon: Icons.favorite_outline_rounded,
              label: 'Wishlist',
              color: Colors.pink,
              onTap: () => context.push('/wishlist'),
            ),
            _Tile(
              icon: Icons.card_giftcard_rounded,
              label: 'Refer & Earn',
              color: AppColors.success,
              onTap: () => context.push('/referral'),
            ),
          ]),

          // ── Preferences ───────────────────────────────────────────────────
          _Section(title: 'Preferences', children: [
            // Language picker
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: AppColors.info, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Language',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        _localeName(context.locale),
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DropdownButton<Locale>(
                  value: context.locale,
                  underline: const SizedBox(),
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(
                        value: Locale('en'), child: Text('English')),
                    DropdownMenuItem(
                        value: Locale('hi'), child: Text('हिन्दी')),
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
              ]),
            ),

            // Dark mode
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.charcoal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_rounded,
                      color: AppColors.charcoal, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                    child: Text('Appearance',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500))),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 14),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.phone_android_rounded, size: 14),
                      label: Text('Auto'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 14),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (s) =>
                      ref.read(themeModeProvider.notifier).setMode(s.first),
                  style: ButtonStyle(
                    textStyle: WidgetStateProperty.all(
                        const TextStyle(fontSize: 11)),
                  ),
                ),
              ]),
            ),

            // Notifications
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.warning, size: 20),
                ),
                const SizedBox(width: 14),
                const Expanded(
                    child: Text('Push Notifications',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500))),
                Switch(
                  value: _notifications,
                  onChanged: _setNotifications,
                ),
              ]),
            ),
            const SizedBox(height: 8),
          ]),

          // ── Support ───────────────────────────────────────────────────────
          _Section(title: 'Support & Legal', children: [
            _Tile(
              icon: Icons.help_outline_rounded,
              label: 'FAQ',
              color: AppColors.info,
              onTap: () => context.push('/faq'),
            ),
            _Tile(
              icon: Icons.support_agent_rounded,
              label: 'Contact Support',
              color: AppColors.violet,
              onTap: () => context.push('/support'),
            ),
            _Tile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              color: AppColors.slate,
              onTap: () => context.push('/privacy-policy'),
            ),
            _Tile(
              icon: Icons.description_outlined,
              label: 'Terms of Service',
              color: AppColors.slate,
              onTap: () => context.push('/terms'),
            ),
          ]),

          const SizedBox(height: 12),

          // Sign out
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () async {
                await ref.read(authControllerProvider).signOut();
                if (context.mounted) context.go('/auth/sign-in');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Jalaram Events v1.0.0 • Made with ❤️ in India',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.slate),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _localeName(Locale l) => switch (l.languageCode) {
        'hi' => 'हिन्दी',
        _ => 'English',
      };
}

// ── Section ───────────────────────────────────────────────────────────────────

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
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.slate,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.violetMid),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label,
          style:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
      onTap: onTap,
      dense: true,
    );
  }
}
