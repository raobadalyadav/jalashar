import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'compare_vendors_screen.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  const VendorDetailScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  ConsumerState<VendorDetailScreen> createState() =>
      _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  bool _saved = false;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final s =
        await ref.read(wishlistRepoProvider).isSaved(widget.vendor.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _toggleWishlist() async {
    setState(() => _toggling = true);
    try {
      await ref.read(wishlistRepoProvider).toggle(widget.vendor.id);
      setState(() => _saved = !_saved);
      ref.invalidate(wishlistProvider);
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final reviews = ref.watch(vendorReviewsProvider(vendor.id));
    final availability = ref.watch(
        FutureProvider.autoDispose<Set<DateTime>>((ref) =>
            ref.watch(availabilityRepoProvider).blockedDates(vendor.id)).future);
    final inCompare = ref.watch(compareVendorsProvider
        .select((list) => list.any((v) => v.id == vendor.id)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 260,
            pinned: true,
            actions: [
              // Compare toggle
              IconButton(
                tooltip: inCompare ? 'Remove from compare' : 'Add to compare',
                onPressed: () {
                  ref
                      .read(compareVendorsProvider.notifier)
                      .toggle(vendor);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(inCompare
                        ? 'Removed from comparison'
                        : 'Added to comparison'),
                    duration: const Duration(seconds: 1),
                  ));
                },
                icon: Icon(
                  inCompare
                      ? Icons.compare_arrows
                      : Icons.compare_arrows_outlined,
                  color: inCompare ? AppColors.saffron : null,
                ),
              ),
              // Wishlist
              IconButton(
                onPressed: _toggling ? null : _toggleWishlist,
                icon: Icon(
                  _saved ? Icons.favorite : Icons.favorite_border,
                  color: _saved ? Colors.red : null,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(vendor.name ?? 'Vendor'),
              background: vendor.portfolioUrls.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: vendor.portfolioUrls.first,
                      fit: BoxFit.cover)
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.saffron, AppColors.deepMaroon],
                        ),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating + tags row
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star,
                            color: AppColors.gold, size: 16),
                        const SizedBox(width: 4),
                        Text(vendor.ratingAvg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Chip(label: Text(vendor.category)),
                    if (vendor.city != null) ...[
                      const SizedBox(width: 6),
                      Chip(
                        avatar: const Icon(Icons.location_on, size: 14),
                        label: Text(vendor.city!),
                      ),
                    ],
                    const Spacer(),
                    if (vendor.isVerified)
                      const Chip(
                        avatar: Icon(Icons.verified,
                            color: Colors.blue, size: 16),
                        label: Text('Verified'),
                      ),
                  ]),

                  const SizedBox(height: 12),

                  if (vendor.basePrice != null)
                    Text(
                      '${Fmt.currency(vendor.basePrice!)} onwards',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.deepMaroon,
                          fontWeight: FontWeight.w800),
                    ),

                  const SizedBox(height: 16),

                  Text('About',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(vendor.bio ?? 'No description available.',
                      style: const TextStyle(height: 1.5)),

                  // Portfolio grid
                  if (vendor.portfolioUrls.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Portfolio',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: vendor.portfolioUrls.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                            imageUrl: vendor.portfolioUrls[i],
                            fit: BoxFit.cover),
                      ),
                    ),
                  ],

                  // Availability mini-calendar
                  const SizedBox(height: 20),
                  Text('Availability',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  FutureBuilder<Set<DateTime>>(
                    future: availability,
                    builder: (_, snap) {
                      final blocked = snap.data ?? {};
                      return _MiniAvailabilityCalendar(
                          blockedDates: blocked);
                    },
                  ),

                  // Reviews
                  const SizedBox(height: 20),
                  Text('Reviews',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  reviews.when(
                    loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) => list.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('No reviews yet'),
                          )
                        : Column(
                            children: list
                                .map((r) => _ReviewCard(review: r))
                                .toList(),
                          ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Message'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => context.push('/booking/new', extra: vendor),
                icon: const Icon(Icons.event_available),
                label: const Text('Book Now'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniAvailabilityCalendar extends StatelessWidget {
  const _MiniAvailabilityCalendar({required this.blockedDates});
  final Set<DateTime> blockedDates;

  bool _isBlocked(DateTime day) => blockedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Show next 21 days
    final days = List.generate(21, (i) => DateTime.now().add(Duration(days: i)));

    return Card(
      elevation: 0,
      color: AppColors.ivory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: 4),
              const Text('Available', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 12),
              const Icon(Icons.circle, size: 10, color: AppColors.danger),
              const SizedBox(width: 4),
              const Text('Blocked', style: TextStyle(fontSize: 11)),
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: days.map((day) {
                final blocked = _isBlocked(day);
                final isToday = day.year == now.year &&
                    day.month == now.month &&
                    day.day == now.day;
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: blocked
                        ? AppColors.danger.withOpacity(0.15)
                        : (isToday
                            ? AppColors.saffron.withOpacity(0.3)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppColors.saffron
                          : blocked
                              ? AppColors.danger.withOpacity(0.5)
                              : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      color: blocked ? AppColors.danger : AppColors.deepMaroon,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final dynamic review;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(review.clientName ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.stars ? Icons.star : Icons.star_border,
                    size: 14,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ]),
            if (review.comment != null) ...[
              const SizedBox(height: 6),
              Text(review.comment!,
                  style: const TextStyle(height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }
}
