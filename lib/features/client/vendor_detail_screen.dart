import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class VendorDetailScreen extends StatelessWidget {
  const VendorDetailScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(vendor.name ?? 'Vendor'),
              background: vendor.portfolioUrls.isNotEmpty
                  ? CachedNetworkImage(imageUrl: vendor.portfolioUrls.first, fit: BoxFit.cover)
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
                  Text('Portfolio', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (vendor.portfolioUrls.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.builder(
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
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
