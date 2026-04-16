import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/models/vendor_meta.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/permissions.dart';

class VendorShell extends ConsumerStatefulWidget {
  const VendorShell({super.key});
  @override
  ConsumerState<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends ConsumerState<VendorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final convosAsync = ref.watch(vendorConversationsProvider);
    final msgUnread = convosAsync.valueOrNull
            ?.fold<int>(0, (s, c) => s + c.unread) ??
        0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          _VendorOverview(),
          _VendorMessages(),
          _VendorBookings(),
          _VendorProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: msgUnread > 0,
              label: Text(msgUnread > 9 ? '9+' : '$msgUnread'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: msgUnread > 0,
              label: Text(msgUnread > 9 ? '9+' : '$msgUnread'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Messages',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Bookings',
          ),
          const NavigationDestination(
            icon: Icon(Icons.store_outlined),
            selectedIcon: Icon(Icons.store_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Overview ──────────────────────────────────────────────────────────────────

class _VendorOverview extends ConsumerWidget {
  const _VendorOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(vendorBookingsProvider);
    final reviews = ref.watch(myVendorReviewsProvider);
    final viewStats = ref.watch(myVendorViewStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Payouts',
            onPressed: () => context.push('/vendor/payouts'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
      body: bookings.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(4, (_) => const SkeletonCard(height: 80)),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(vendorBookingsProvider),
        ),
        data: (list) {
          final pending =
              list.where((b) => b.status == BookingStatus.pending).length;
          final confirmed =
              list.where((b) => b.status == BookingStatus.confirmed).length;
          final completed =
              list.where((b) => b.status == BookingStatus.completed).length;
          final totalEarnings = list
              .where((b) => b.status == BookingStatus.completed)
              .fold<double>(0, (s, b) => s + b.totalAmount);
          final thisMonth = list.where((b) {
            final now = DateTime.now();
            return b.eventDate.year == now.year &&
                b.eventDate.month == now.month;
          }).length;

          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(vendorBookingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats grid
                Row(children: [
                  Expanded(
                    child: _StatTile(
                      title: 'Pending',
                      value: '$pending',
                      icon: Icons.hourglass_top_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      title: 'Confirmed',
                      value: '$confirmed',
                      icon: Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                  ),
                ]).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: _StatTile(
                      title: 'This Month',
                      value: '$thisMonth',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.violet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      title: 'Completed',
                      value: '$completed',
                      icon: Icons.done_all_rounded,
                      color: AppColors.info,
                    ),
                  ),
                ]).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 12),

                // Earnings card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.violetDeep, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Earnings',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          Fmt.currency(totalEarnings),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 28),
                    ),
                  ]),
                ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1),

                const SizedBox(height: 12),

                // Profile view stats
                viewStats.when(
                  data: (stats) => stats == null
                      ? const SizedBox.shrink()
                      : Row(children: [
                          Expanded(
                            child: _StatTile(
                              title: '7-Day Views',
                              value: '${stats.views7d}',
                              icon: Icons.visibility_outlined,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              title: '30-Day Views',
                              value: '${stats.views30d}',
                              icon: Icons.bar_chart_rounded,
                              color: AppColors.saffron,
                            ),
                          ),
                        ]).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                // Rating breakdown
                reviews.when(
                  data: (revList) => revList.isEmpty
                      ? const SizedBox.shrink()
                      : _RatingBreakdown(reviews: revList),
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),

                const SizedBox(height: 20),

                Text('Recent Bookings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 12),
                if (list.isEmpty)
                  EmptyState(
                    icon: Icons.event_note_rounded,
                    title: 'No bookings yet',
                    subtitle: 'Bookings from clients will appear here',
                  )
                else
                  ...list.take(5).map((b) => _RecentBookingTile(booking: b)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: color,
                  )),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.slate)),
        ],
      ),
    );
  }
}

class _RatingBreakdown extends StatelessWidget {
  const _RatingBreakdown({required this.reviews});
  final List<Review> reviews;

  @override
  Widget build(BuildContext context) {
    final avg = reviews.isEmpty
        ? 0.0
        : reviews.fold<double>(0, (s, r) => s + r.stars) / reviews.length;
    final counts = List.generate(5, (i) {
      final star = 5 - i;
      return reviews.where((r) => r.stars == star).length;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violetMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
            const SizedBox(width: 6),
            Text('Ratings & Reviews',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const Spacer(),
            Text('(${reviews.length})',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.slate)),
          ]),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Column(children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < avg.round()
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.gold,
                    size: 14,
                  ),
                ),
              ),
            ]),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  final star = 5 - i;
                  final count = counts[i];
                  final pct =
                      reviews.isEmpty ? 0.0 : count / reviews.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Text('$star',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 11),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.violetMid,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.slate)),
                      ),
                    ]),
                  );
                }),
              ),
            ),
          ]),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1);
  }
}

class _RecentBookingTile extends StatelessWidget {
  const _RecentBookingTile({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (booking.status) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.confirmed => AppColors.success,
      BookingStatus.completed => AppColors.info,
      BookingStatus.cancelled => AppColors.danger,
      _ => AppColors.slate,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(Fmt.date(booking.eventDate),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            Text(booking.venue ?? 'No venue', style: const TextStyle(fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadge(label: booking.status.label, color: statusColor),
            const SizedBox(height: 4),
            Text(Fmt.currency(booking.totalAmount),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.violet)),
          ],
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}

// ── Messages Tab ──────────────────────────────────────────────────────────────

class _VendorMessages extends ConsumerWidget {
  const _VendorMessages();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(vendorConversationsProvider);
    final me = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(vendorConversationsProvider),
          ),
        ],
      ),
      body: convos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle: 'Client messages will appear here after they book you',
            );
          }
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(vendorConversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: list.length,
              separatorBuilder: (c, i) =>
                  const Divider(height: 1, indent: 72, endIndent: 16),
              itemBuilder: (_, i) {
                final c = list[i];
                final booking = c.booking;
                final lastMsg = c.lastMsg;
                final isMine = lastMsg?.senderId == me;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      gradient: AppColors.brandGradient,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'C',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18),
                    ),
                  ),
                  title: Row(children: [
                    Expanded(
                      child: Text(
                        'Booking #${booking.id.substring(0, 6).toUpperCase()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (lastMsg != null)
                      Text(
                        Fmt.timeAgo(lastMsg.createdAt),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate),
                      ),
                  ]),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(children: [
                        if (isMine)
                          const Text('You: ',
                              style: TextStyle(
                                  color: AppColors.slate, fontSize: 12)),
                        Expanded(
                          child: Text(
                            lastMsg?.content ?? 'Start conversation →',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: lastMsg == null
                                  ? AppColors.violet
                                  : AppColors.slate,
                              fontSize: 13,
                              fontStyle: lastMsg == null
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                        ),
                        if (c.unread > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.violet,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              c.unread > 9 ? '9+' : '${c.unread}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        '${booking.status.label} · ${Fmt.date(booking.eventDate)}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate),
                      ),
                    ],
                  ),
                  onTap: () => context.push(
                      '/chat/${booking.id}/${booking.clientId}'),
                ).animate()
                    .fadeIn(delay: Duration(milliseconds: i * 40))
                    .slideX(begin: -0.05);
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Bookings Tab ──────────────────────────────────────────────────────────────

class _VendorBookings extends ConsumerWidget {
  const _VendorBookings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(vendorBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bookings')),
      body: bookings.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(5, (_) => const SkeletonCard(height: 120)),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(vendorBookingsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.event_note_rounded,
              title: 'No bookings yet',
              subtitle: 'Your client bookings will appear here',
            );
          }
          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(vendorBookingsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _BookingCard(booking: list[i])
                  .animate(delay: Duration(milliseconds: i * 60))
                  .fadeIn()
                  .slideY(begin: 0.05),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = booking.status == BookingStatus.pending;
    final statusColor = switch (booking.status) {
      BookingStatus.pending => AppColors.warning,
      BookingStatus.confirmed => AppColors.success,
      BookingStatus.completed => AppColors.info,
      BookingStatus.cancelled => AppColors.danger,
      _ => AppColors.slate,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(children: [
              Icon(Icons.event_rounded, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(Fmt.date(booking.eventDate),
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: statusColor)),
              const Spacer(),
              StatusBadge(label: booking.status.label, color: statusColor),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (booking.venue != null)
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        size: 14, color: AppColors.slate),
                    const SizedBox(width: 4),
                    Text(booking.venue!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                const SizedBox(height: 6),
                Row(children: [
                  Text('Total: ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.slate)),
                  Text(Fmt.currency(booking.totalAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.violet,
                          fontSize: 15)),
                ]),
                if (isPending) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await ref
                              .read(bookingRepoProvider)
                              .updateStatus(booking.id, BookingStatus.confirmed);
                          ref.invalidate(vendorBookingsProvider);
                        },
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Accept'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await ref
                              .read(bookingRepoProvider)
                              .updateStatus(
                                  booking.id, BookingStatus.cancelled);
                          ref.invalidate(vendorBookingsProvider);
                        },
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Decline'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side:
                              const BorderSide(color: AppColors.danger),
                          minimumSize: const Size(0, 42),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Chat CTA
                    IconButton.outlined(
                      onPressed: () => context.push(
                          '/chat/${booking.id}/${booking.clientId}'),
                      icon: const Icon(Icons.chat_outlined, size: 18),
                      tooltip: 'Chat',
                    ),
                  ]),
                ] else ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    // Mark event complete (for confirmed bookings where event date passed)
                    if (booking.status == BookingStatus.confirmed &&
                        !booking.eventDate.isAfter(DateTime.now()))
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(bookingRepoProvider)
                                .updateStatus(booking.id, BookingStatus.completed);
                            ref.invalidate(vendorBookingsProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Marked as completed! Client will be asked to review.'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                          label: const Text('Mark Complete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.success,
                            minimumSize: const Size(0, 40),
                          ),
                        ),
                      ),
                    if (booking.status == BookingStatus.confirmed &&
                        !booking.eventDate.isAfter(DateTime.now()))
                      const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.push(
                          '/chat/${booking.id}/${booking.clientId}'),
                      icon: const Icon(Icons.chat_outlined, size: 16),
                      label: const Text('Chat'),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Profile Tab ───────────────────────────────────────────────────────────────

class _VendorProfile extends ConsumerStatefulWidget {
  const _VendorProfile();
  @override
  ConsumerState<_VendorProfile> createState() => _VendorProfileState();
}

class _VendorProfileState extends ConsumerState<_VendorProfile> {
  final _category = TextEditingController();
  final _bio = TextEditingController();
  final _tagline = TextEditingController();
  final _city = TextEditingController();
  final _address = TextEditingController();
  final _price = TextEditingController();
  final _phone = TextEditingController();
  final _whatsapp = TextEditingController();
  final _instagram = TextEditingController();
  final _youtube = TextEditingController();
  final _facebook = TextEditingController();
  final _yearsExp = TextEditingController();
  final List<String> _portfolio = [];
  List<String> _serviceCities = [];
  List<String> _languages = [];
  bool _fullyBooked = false;
  Map<String, dynamic> _meta = {};
  final Map<String, TextEditingController> _metaCtrls = {};
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadExisting();
    }
  }

  @override
  void dispose() {
    _category.dispose();
    _bio.dispose();
    _tagline.dispose();
    _city.dispose();
    _address.dispose();
    _price.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    _instagram.dispose();
    _youtube.dispose();
    _facebook.dispose();
    _yearsExp.dispose();
    for (final c in _metaCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final vendor = await ref.read(vendorRepoProvider).myVendor();
      if (vendor != null && mounted) {
        _category.text = vendor.category;
        _bio.text = vendor.bio ?? '';
        _tagline.text = vendor.tagline ?? '';
        _city.text = vendor.city ?? '';
        _address.text = vendor.address ?? '';
        _price.text = vendor.basePrice?.toString() ?? '';
        _phone.text = vendor.phone ?? '';
        _whatsapp.text = vendor.whatsapp ?? '';
        _instagram.text = vendor.instagramUrl ?? '';
        _youtube.text = vendor.youtubeUrl ?? '';
        _facebook.text = vendor.facebookUrl ?? '';
        _yearsExp.text = vendor.yearsExperience > 0
            ? vendor.yearsExperience.toString()
            : '';
        setState(() {
          _portfolio.addAll(vendor.portfolioUrls);
          _serviceCities = List<String>.from(vendor.serviceCities);
          _languages = List<String>.from(vendor.languages);
          _fullyBooked = vendor.fullyBooked;
          _meta = Map<String, dynamic>.from(vendor.meta);
        });
      }
    } catch (_) {}
  }

  int _completionPercent() {
    int filled = 0;
    const total = 10;
    if (_category.text.isNotEmpty) filled++;
    if (_bio.text.isNotEmpty) filled++;
    if (_city.text.isNotEmpty) filled++;
    if (_phone.text.isNotEmpty) filled++;
    if (_price.text.isNotEmpty) filled++;
    if (_portfolio.isNotEmpty) filled++;
    if (_address.text.isNotEmpty) filled++;
    if (_tagline.text.isNotEmpty) filled++;
    if (_instagram.text.isNotEmpty ||
        _youtube.text.isNotEmpty ||
        _facebook.text.isNotEmpty) {
      filled++;
    }
    if (_serviceCities.isNotEmpty) filled++;
    return (filled / total * 100).round();
  }

  TextEditingController _metaCtrl(String key) =>
      _metaCtrls.putIfAbsent(key, () => TextEditingController(
            text: _meta[key]?.toString() ?? '',
          ));

  Future<void> _addPhoto() async {
    if (!await AppPermissions.photos()) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _loading = true);
    try {
      final url =
          await ref.read(storageRepoProvider).uploadPortfolio(File(picked.path));
      setState(() => _portfolio.add(url));
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_category.text.isEmpty) {
      AppSnack.error(context, 'Category is required');
      return;
    }
    setState(() => _loading = true);
    try {
      // Flush text-based meta controllers into _meta map
      for (final entry in _metaCtrls.entries) {
        _meta[entry.key] = entry.value.text.trim();
      }
      await ref.read(vendorRepoProvider).upsertMyVendor(
            category: _category.text.trim(),
            bio: _bio.text.trim(),
            city: _city.text.trim(),
            basePrice: double.tryParse(_price.text) ?? 0,
            portfolioUrls: _portfolio,
            meta: _meta,
            tagline: _tagline.text.trim(),
            phone: _phone.text.trim(),
            whatsapp: _whatsapp.text.trim(),
            address: _address.text.trim(),
            yearsExperience: int.tryParse(_yearsExp.text) ?? 0,
            serviceCities: _serviceCities,
            languages: _languages,
            instagramUrl: _instagram.text.trim(),
            youtubeUrl: _youtube.text.trim(),
            facebookUrl: _facebook.text.trim(),
            fullyBooked: _fullyBooked,
          );
      if (mounted) AppSnack.success(context, 'Profile saved successfully');
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildCompletionMeter() {
    final pct = _completionPercent();
    final color = pct < 40
        ? AppColors.danger
        : pct < 70
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.analytics_outlined, color: color, size: 18),
            const SizedBox(width: 8),
            Text('Profile Completeness',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: color)),
            const Spacer(),
            Text('$pct%',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: color)),
          ]),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pct < 50
                ? 'Add phone, address, portfolio & social links to attract more clients.'
                : pct < 80
                    ? 'Great start! Complete remaining fields to rank higher.'
                    : 'Excellent profile! You\'re highly visible to clients.',
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Future<void> _addCityDialog() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Service City'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Mumbai, Pune'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result != null && result.isNotEmpty && !_serviceCities.contains(result)) {
      setState(() => _serviceCities.add(result));
    }
  }

  Widget _buildSpecializationsSection() {
    final fields = VendorCategoryMeta.forCategory(_category.text.toLowerCase());
    return _SectionCard(
      title: 'Specializations',
      icon: Icons.star_outline_rounded,
      children: [
        for (final field in fields) ...[
          Text(field.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          if (field.type == MetaFieldType.multiselect) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: field.options.map((opt) {
                final selected =
                    (_meta[field.key] as List? ?? []).contains(opt);
                return FilterChip(
                  label: Text(opt, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  selectedColor: AppColors.violet.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.violet,
                  onSelected: (v) {
                    setState(() {
                      final list =
                          List<String>.from(_meta[field.key] as List? ?? []);
                      if (v) {
                        list.add(opt);
                      } else {
                        list.remove(opt);
                      }
                      _meta[field.key] = list;
                    });
                  },
                );
              }).toList(),
            ),
          ] else ...[
            TextField(
              controller: _metaCtrl(field.key),
              keyboardType: field.type == MetaFieldType.number
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                hintText: field.label,
                isDense: true,
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
      body: LoadingOverlay(
        loading: _loading,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile completion meter
            _buildCompletionMeter(),
            const SizedBox(height: 16),

            // Section: Business Info
            _SectionCard(
              title: 'Business Information',
              icon: Icons.business_center_rounded,
              children: [
                TextField(
                  controller: _category,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Category *',
                    hintText: 'photographer, dj, caterer…',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagline,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Tagline / One-liner',
                    hintText: 'e.g. Capturing your best moments since 2010',
                    prefixIcon: Icon(Icons.short_text_rounded),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'About your business',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _city,
                      decoration: const InputDecoration(
                        labelText: 'Primary City *',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _yearsExp,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Years Experience',
                        prefixIcon: Icon(Icons.timeline_rounded),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _address,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Full Address',
                    hintText: 'Street, Area, City, PIN',
                    prefixIcon: Icon(Icons.location_on_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Starting Price (₹) *',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Contact Info
            _SectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone_outlined,
              children: [
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Business Phone *',
                    prefixIcon: Icon(Icons.phone_outlined),
                    hintText: '+91 XXXXX XXXXX',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _whatsapp,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp Number',
                    prefixIcon: Icon(Icons.chat_outlined),
                    hintText: 'Leave blank if same as phone',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Service Cities
            _SectionCard(
              title: 'Service Area',
              icon: Icons.map_outlined,
              children: [
                const Text('Cities you serve:',
                    style: TextStyle(fontSize: 12, color: AppColors.slate)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._serviceCities.map((city) => Chip(
                          label: Text(city),
                          onDeleted: () =>
                              setState(() => _serviceCities.remove(city)),
                          deleteIconColor: AppColors.slate,
                        )),
                    ActionChip(
                      avatar: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add City'),
                      onPressed: () => _addCityDialog(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Languages
            _SectionCard(
              title: 'Languages Spoken',
              icon: Icons.language_outlined,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: ['Hindi', 'English', 'Marathi', 'Gujarati',
                      'Tamil', 'Telugu', 'Kannada', 'Bengali', 'Punjabi']
                      .map((lang) => FilterChip(
                            label: Text(lang),
                            selected: _languages.contains(lang),
                            selectedColor: AppColors.violet.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.violet,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _languages.add(lang);
                              } else {
                                _languages.remove(lang);
                              }
                            }),
                          ))
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Social Media
            _SectionCard(
              title: 'Social Media & Links',
              icon: Icons.share_outlined,
              children: [
                TextField(
                  controller: _instagram,
                  decoration: const InputDecoration(
                    labelText: 'Instagram Profile URL',
                    prefixIcon: Icon(Icons.camera_alt_outlined),
                    hintText: 'https://instagram.com/yourprofile',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _youtube,
                  decoration: const InputDecoration(
                    labelText: 'YouTube Channel URL',
                    prefixIcon: Icon(Icons.play_circle_outline_rounded),
                    hintText: 'https://youtube.com/@yourchannel',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _facebook,
                  decoration: const InputDecoration(
                    labelText: 'Facebook Page URL',
                    prefixIcon: Icon(Icons.facebook_outlined),
                    hintText: 'https://facebook.com/yourpage',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Availability toggle
            _SectionCard(
              title: 'Availability Status',
              icon: Icons.event_available_outlined,
              children: [
                Row(children: [
                  const Icon(Icons.block_rounded, color: AppColors.danger, size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Mark as Fully Booked',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  Switch.adaptive(
                    value: _fullyBooked,
                    activeThumbColor: AppColors.danger,
                    onChanged: (v) => setState(() => _fullyBooked = v),
                  ),
                ]),
                if (_fullyBooked)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 28),
                    child: Text(
                      'Clients will see you\'re fully booked and cannot send new requests.',
                      style: TextStyle(fontSize: 12, color: AppColors.danger),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Specializations (category-specific)
            if (VendorCategoryMeta.hasFields(_category.text.toLowerCase()))
              _buildSpecializationsSection(),
            if (VendorCategoryMeta.hasFields(_category.text.toLowerCase()))
              const SizedBox(height: 16),

            // Section: Packages & Pricing
            _SectionCard(
              title: 'Packages & Pricing',
              icon: Icons.inventory_2_outlined,
              trailing: TextButton.icon(
                onPressed: () => context.push('/vendor/packages'),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Manage'),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.violet.withValues(alpha: 0.08),
                        AppColors.violetDeep.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.violet, size: 18),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Set pricing for Wedding, Birthday, Corporate & more. Clients can see your packages before booking.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section: Portfolio
            _SectionCard(
              title: 'Portfolio',
              icon: Icons.photo_library_outlined,
              trailing: TextButton.icon(
                onPressed: _loading ? null : _addPhoto,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('Add Photo'),
              ),
              children: [
                if (_portfolio.isEmpty)
                  Container(
                    height: 80,
                    alignment: Alignment.center,
                    child: Text(
                      'Add photos to showcase your work',
                      style: TextStyle(color: AppColors.slate),
                    ),
                  )
                else
                  SizedBox(
                    height: 110,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _portfolio.length,
                      separatorBuilder: (c, i) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: _portfolio[i],
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _portfolio.removeAt(i)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            GradientButton(
              label: 'Save Profile',
              icon: Icons.save_rounded,
              onPressed: _loading ? null : _save,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.violetMid),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.violet, size: 20),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            if (trailing != null) ...[const Spacer(), trailing!],
          ]),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
