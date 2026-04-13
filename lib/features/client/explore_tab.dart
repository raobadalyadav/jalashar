import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

final _selectedCategoryProvider = StateProvider<String?>((_) => null);

class ExploreTab extends ConsumerWidget {
  const ExploreTab({super.key});

  static const _categories = [
    ('All', null, Icons.apps),
    ('Photographer', 'photographer', Icons.camera_alt),
    ('Makeup', 'makeup', Icons.brush),
    ('DJ', 'dj', Icons.music_note),
    ('Caterer', 'caterer', Icons.restaurant),
    ('Decorator', 'decorator', Icons.celebration),
    ('Mehendi', 'mehendi', Icons.pan_tool),
    ('Pandit', 'pandit', Icons.temple_hindu),
    ('Florist', 'florist', Icons.local_florist),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(_selectedCategoryProvider);
    final vendors = ref.watch(vendorListProvider(cat));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Vendors'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SizedBox(
            height: 60,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, slug, icon) = _categories[i];
                final selected = cat == slug;
                return FilterChip(
                  selected: selected,
                  onSelected: (_) =>
                      ref.read(_selectedCategoryProvider.notifier).state = slug,
                  avatar: Icon(icon, size: 18),
                  label: Text(label),
                );
              },
            ),
          ),
        ),
      ),
      body: vendors.when(
        loading: () => _ShimmerList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No vendors found'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(vendorListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) => _VendorTile(vendor: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _VendorTile extends StatelessWidget {
  const _VendorTile({required this.vendor});
  final Vendor vendor;
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/vendor-detail/${vendor.id}', extra: vendor),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 80,
                height: 80,
                child: vendor.avatarUrl != null
                    ? CachedNetworkImage(imageUrl: vendor.avatarUrl!, fit: BoxFit.cover)
                    : Container(
                        color: AppColors.ivory,
                        child: const Icon(Icons.storefront,
                            size: 36, color: AppColors.deepMaroon),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(vendor.name ?? 'Vendor',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (vendor.isVerified)
                      const Icon(Icons.verified, color: Colors.blue, size: 18),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    '${vendor.category} · ${vendor.city ?? ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.star, color: AppColors.gold, size: 16),
                    const SizedBox(width: 2),
                    Text(vendor.ratingAvg.toStringAsFixed(1)),
                    const SizedBox(width: 12),
                    Text(
                      vendor.basePrice != null
                          ? '${Fmt.currency(vendor.basePrice!)} onwards'
                          : '',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 104,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
