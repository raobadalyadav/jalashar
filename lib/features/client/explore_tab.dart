import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';
import 'compare_vendors_screen.dart';

final _selectedCategoryProvider = StateProvider<String?>((_) => null);
final _gridModeProvider = StateProvider<bool>((_) => false);

class ExploreTab extends ConsumerWidget {
  const ExploreTab({super.key});

  static const _categories = [
    ('All', null, Icons.apps_rounded),
    ('Photographer', 'photographer', Icons.camera_alt_rounded),
    ('Makeup', 'makeup', Icons.brush_rounded),
    ('DJ', 'dj', Icons.music_note_rounded),
    ('Caterer', 'caterer', Icons.restaurant_rounded),
    ('Decorator', 'decorator', Icons.celebration_rounded),
    ('Mehendi', 'mehendi', Icons.pan_tool_rounded),
    ('Pandit', 'pandit', Icons.temple_hindu_rounded),
    ('Florist', 'florist', Icons.local_florist_rounded),
    ('Band', 'band', Icons.queue_music_rounded),
    ('Videographer', 'videographer', Icons.videocam_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cat = ref.watch(_selectedCategoryProvider);
    final vendors = ref.watch(vendorListProvider(cat));
    final compareList = ref.watch(compareVendorsProvider);
    final gridMode = ref.watch(_gridModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Vendors'),
        actions: [
          IconButton(
            icon: Icon(gridMode
                ? Icons.view_list_rounded
                : Icons.grid_view_rounded),
            tooltip: gridMode ? 'List view' : 'Grid view',
            onPressed: () =>
                ref.read(_gridModeProvider.notifier).state = !gridMode,
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, slug, icon) = _categories[i];
                final selected = cat == slug;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: FilterChip(
                    selected: selected,
                    onSelected: (_) => ref
                        .read(_selectedCategoryProvider.notifier)
                        .state = slug,
                    avatar: Icon(icon,
                        size: 16,
                        color: selected ? Colors.white : AppColors.slate),
                    label: Text(label),
                    selectedColor: AppColors.violet,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.charcoal,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 12,
                    ),
                    backgroundColor: context.softSurface,
                    checkmarkColor: Colors.white,
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          vendors.when(
            loading: () => ListView(
              padding: const EdgeInsets.all(16),
              children: List.generate(5, (_) => const SkeletonCard(height: 110)),
            ),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(vendorListProvider),
            ),
            data: (list) {
              if (list.isEmpty) {
                return EmptyState(
                  icon: Icons.storefront_rounded,
                  title: 'No vendors found',
                  subtitle: 'Try a different category',
                );
              }
              final bottomPad = compareList.isEmpty ? 16.0 : 96.0;
              return RefreshIndicator(
                color: AppColors.violet,
                onRefresh: () async => ref.invalidate(vendorListProvider),
                child: gridMode
                    ? GridView.builder(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: list.length,
                        itemBuilder: (_, i) =>
                            _VendorGridCard(vendor: list[i])
                                .animate(
                                    delay: Duration(milliseconds: i * 40))
                                .fadeIn(),
                      )
                    : ListView.builder(
                        padding:
                            EdgeInsets.fromLTRB(16, 16, 16, bottomPad),
                        itemCount: list.length,
                        itemBuilder: (_, i) => _VendorCard(vendor: list[i])
                            .animate(
                                delay: Duration(milliseconds: i * 60))
                            .fadeIn()
                            .slideY(begin: 0.1),
                      ),
              );
            },
          ),
          // Compare bar floats above list
          if (compareList.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: CompareBar(),
            ),
        ],
      ),
    );
  }
}

class _VendorCard extends ConsumerWidget {
  const _VendorCard({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compareList = ref.watch(compareVendorsProvider);
    final inCompare = compareList.any((v) => v.id == vendor.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.push('/vendor-detail/${vendor.id}', extra: vendor),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar
              Hero(
                tag: 'vendor-avatar-${vendor.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 84,
                    height: 84,
                    child: vendor.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: vendor.avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (c, u) => Container(
                              color: context.midSurface,
                              child: const Icon(Icons.storefront_rounded,
                                  color: AppColors.violet, size: 32),
                            ),
                            errorWidget: (c, u, e) => Container(
                              color: context.midSurface,
                              child: const Icon(Icons.storefront_rounded,
                                  color: AppColors.violet, size: 32),
                            ),
                          )
                        : Container(
                            color: context.midSurface,
                            child: const Icon(Icons.storefront_rounded,
                                color: AppColors.violet, size: 32),
                          ),
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
                        child: Text(
                          vendor.name ?? 'Vendor',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                      ),
                      if (vendor.isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.info.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: AppColors.info, size: 12),
                              const SizedBox(width: 2),
                              Text('Verified',
                                  style: TextStyle(
                                      color: AppColors.info,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.midSurface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          vendor.category,
                          style: const TextStyle(
                              color: AppColors.violet,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (vendor.city != null) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_rounded,
                            size: 12, color: AppColors.slate),
                        Text(vendor.city!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.slate)),
                      ],
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_rounded,
                          color: AppColors.gold, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        vendor.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      const Spacer(),
                      if (vendor.basePrice != null)
                        Text(
                          Fmt.currency(vendor.basePrice!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppColors.violet,
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
              // Compare toggle
              GestureDetector(
                onTap: () =>
                    ref.read(compareVendorsProvider.notifier).toggle(vendor),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: inCompare ? AppColors.violet : context.softSurface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    inCompare ? Icons.compare_arrows : Icons.add,
                    size: 16,
                    color: inCompare ? Colors.white : AppColors.violet,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorGridCard extends ConsumerWidget {
  const _VendorGridCard({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/vendor-detail/${vendor.id}', extra: vendor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  vendor.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: vendor.avatarUrl!,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                              color: context.midSurface),
                        )
                      : Container(
                          color: context.midSurface,
                          child: const Icon(Icons.storefront_rounded,
                              color: AppColors.violet, size: 40),
                        ),
                  if (vendor.isVerified)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_rounded,
                            color: Colors.white, size: 12),
                      ),
                    ),
                  if (vendor.badgeTop10)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('Top 10',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.name ?? 'Vendor',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 12),
                    const SizedBox(width: 2),
                    Text(vendor.ratingAvg.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (vendor.basePrice != null)
                      Text(
                        Fmt.currency(vendor.basePrice!),
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.violet),
                      ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
