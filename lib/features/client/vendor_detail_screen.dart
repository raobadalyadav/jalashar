import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/extra_repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  const VendorDetailScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
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
    final s = await ref.read(wishlistRepoProvider).isSaved(widget.vendor.id);
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 260,
            pinned: true,
            actions: [
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
                      imageUrl: vendor.portfolioUrls.first, fit: BoxFit.cover)
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
                  Row(children: [
                    const Icon(Icons.star, color: AppColors.gold),
                    Text(' ${vendor.ratingAvg.toStringAsFixed(1)} · ',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${vendor.category} · ${vendor.city ?? ""}'),
                    const Spacer(),
                    if (vendor.isVerified)
                      const Chip(
                        avatar: Icon(Icons.verified, color: Colors.blue, size: 16),
                        label: Text('Verified'),
                      ),
                  ]),
                  const SizedBox(height: 12),
                  if (vendor.basePrice != null)
                    Text('${Fmt.currency(vendor.basePrice!)} onwards',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.deepMaroon, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  Text('About', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(vendor.bio ?? 'No description available.'),
                  const SizedBox(height: 20),
                  if (vendor.portfolioUrls.isNotEmpty) ...[
                    Text('Portfolio', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: vendor.portfolioUrls.length,
                      itemBuilder: (_, i) => ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                            imageUrl: vendor.portfolioUrls[i], fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  reviews.when(
                    loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator())),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) => list.isEmpty
                        ? const Text('No reviews yet')
                        : Column(
                            children: list
                                .map((r) => Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(r.clientName ?? 'User',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w600)),
                                                const Spacer(),
                                                ...List.generate(
                                                  5,
                                                  (i) => Icon(
                                                    i < r.stars
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    size: 14,
                                                    color: AppColors.gold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (r.comment != null) ...[
                                              const SizedBox(height: 4),
                                              Text(r.comment!),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ))
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
              child: FilledButton(
                onPressed: () => context.push('/booking/new', extra: vendor),
                child: const Text('Book Now'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
