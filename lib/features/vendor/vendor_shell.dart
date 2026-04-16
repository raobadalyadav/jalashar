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

                const SizedBox(height: 20),

                // Rating breakdown
                reviews.when(
                  data: (revList) => revList.isEmpty
                      ? const SizedBox.shrink()
                      : _RatingBreakdown(reviews: revList),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
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
                    fontWeight: FontWeight.w800,
                    color: AppColors.charcoal),
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
              separatorBuilder: (_, __) =>
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
                    const Spacer(),
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
  final _city = TextEditingController();
  final _price = TextEditingController();
  final List<String> _portfolio = [];
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
    _city.dispose();
    _price.dispose();
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
        _city.text = vendor.city ?? '';
        _price.text = vendor.basePrice?.toString() ?? '';
        setState(() {
          _portfolio.addAll(vendor.portfolioUrls);
          _meta = Map<String, dynamic>.from(vendor.meta);
        });
      }
    } catch (_) {}
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
          );
      if (mounted) AppSnack.success(context, 'Profile saved successfully');
    } catch (e) {
      if (mounted) AppSnack.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
            // Section: Business Info
            _SectionCard(
              title: 'Business Information',
              icon: Icons.business_center_rounded,
              children: [
                TextField(
                  controller: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    hintText: 'photographer, dj, caterer…',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bio,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'About your business',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _city,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Base Price (₹)',
                    prefixIcon: Icon(Icons.currency_rupee_rounded),
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
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
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
