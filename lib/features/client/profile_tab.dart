import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final bookings = ref.watch(myBookingsProvider);

    return Scaffold(
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(currentUserProvider)),
        data: (u) => RefreshIndicator(
          color: AppColors.violet,
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(myBookingsProvider);
          },
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.violetDeep, AppColors.violet],
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Profile',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.settings_rounded,
                                    color: Colors.white70),
                                onPressed: () => context.push('/settings'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            // Avatar — image if available, gradient initials if not
                            Stack(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: ClipOval(
                                    child: u?.avatarUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: u!.avatarUrl!,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.violetMid,
                                            ),
                                          )
                                        : Container(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFF9333EA),
                                                  AppColors.gold,
                                                ],
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              _initials(u?.name),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 28,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => context.push('/profile/edit'),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: AppColors.gold,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    u?.name ?? 'Guest User',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    u?.email ?? u?.phone ?? '',
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      u?.role.value.toUpperCase() ?? 'CLIENT',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(),
              ),

              // Stats row
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 4,
                      shadowColor: AppColors.violet.withValues(alpha: 0.15),
                      child: bookings.when(
                        loading: () => const SizedBox(height: 80),
                        error: (_, __) => const SizedBox(height: 80),
                        data: (list) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 8),
                          child: Row(
                            children: [
                              _StatCell(
                                value: '${list.length}',
                                label: 'Total\nBookings',
                                color: AppColors.violet,
                              ),
                              _Divider(),
                              _StatCell(
                                value:
                                    '${list.where((b) => b.status == BookingStatus.confirmed).length}',
                                label: 'Confirmed',
                                color: AppColors.success,
                              ),
                              _Divider(),
                              _StatCell(
                                value:
                                    '${list.where((b) => b.status == BookingStatus.completed).length}',
                                label: 'Completed',
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              ),

              // Menu items
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _MenuSection(
                      title: 'Events',
                      items: [
                        _MenuItem(
                          icon: Icons.event_note_rounded,
                          label: 'My Bookings',
                          color: AppColors.violet,
                          onTap: () {}, // already on bookings tab
                        ),
                        _MenuItem(
                          icon: Icons.favorite_rounded,
                          label: 'Wishlist',
                          color: Colors.pink,
                          onTap: () => context.push('/wishlist'),
                        ),
                        _MenuItem(
                          icon: Icons.compare_arrows_rounded,
                          label: 'Compare Vendors',
                          color: AppColors.info,
                          onTap: () => context.push('/compare'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MenuSection(
                      title: 'Account',
                      items: [
                        _MenuItem(
                          icon: Icons.person_outline_rounded,
                          label: 'Edit Profile',
                          color: AppColors.violet,
                          onTap: () => context.push('/profile/edit'),
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          color: AppColors.warning,
                          onTap: () => context.push('/notifications'),
                        ),
                        _MenuItem(
                          icon: Icons.settings_outlined,
                          label: 'Settings',
                          color: AppColors.slate,
                          onTap: () => context.push('/settings'),
                        ),
                        _MenuItem(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Refer & Earn',
                          color: AppColors.success,
                          badge: '₹200',
                          onTap: () => context.push('/referral'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _MenuSection(
                      title: 'Help',
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'FAQ',
                          color: AppColors.info,
                          onTap: () => context.push('/faq'),
                        ),
                        _MenuItem(
                          icon: Icons.support_agent_rounded,
                          label: 'Support',
                          color: AppColors.violet,
                          onTap: () => context.push('/support'),
                        ),
                        _MenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          color: AppColors.slate,
                          onTap: () => context.push('/privacy-policy'),
                        ),
                        _MenuItem(
                          icon: Icons.article_outlined,
                          label: 'Terms of Service',
                          color: AppColors.slate,
                          onTap: () => context.push('/terms'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Sign out
                    OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, ref),
                      icon: const Icon(Icons.logout_rounded,
                          color: AppColors.danger),
                      label: const Text('Sign Out',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Jalaram Events v1.0.0',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.slate),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      ref.read(authControllerProvider).signOut();
    }
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  const _StatCell(
      {required this.value, required this.label, required this.color});
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.violetMid,
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.slate,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.violetMid),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    title: Text(
                      item.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    trailing: item.badge != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right_rounded,
                            color: AppColors.slate, size: 20),
                    onTap: item.onTap,
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: i == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        topRight: i == 0
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomLeft: i == items.length - 1
                            ? const Radius.circular(16)
                            : Radius.zero,
                        bottomRight: i == items.length - 1
                            ? const Radius.circular(16)
                            : Radius.zero,
                      ),
                    ),
                  ),
                  if (i < items.length - 1)
                    const Divider(
                        height: 1, indent: 56, endIndent: 16),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
}
