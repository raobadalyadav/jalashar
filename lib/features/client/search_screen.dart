import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/repositories.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

enum _SortOption { topRated, priceLow, priceHigh, featured }

final _searchQueryProvider = StateProvider<String>((_) => '');
final _filterCategoryProvider = StateProvider<String?>((_) => null);
final _filterCityProvider = StateProvider<String?>((_) => null);
final _filterEventTypeProvider = StateProvider<String?>((_) => null);
final _filterMinRatingProvider = StateProvider<double>((_) => 0);
final _filterMinPriceProvider = StateProvider<double>((_) => 0);
final _filterMaxPriceProvider = StateProvider<double>((_) => 0);
final _filterVerifiedOnlyProvider = StateProvider<bool>((_) => false);
final _filterHideFullyBookedProvider = StateProvider<bool>((_) => false);
final _filterLanguageProvider = StateProvider<String?>((_) => null);
final _filterDateProvider = StateProvider<DateTime?>((_) => null);
final _sortProvider = StateProvider<_SortOption>((_) => _SortOption.topRated);

const _eventTypes = [
  'Wedding', 'Engagement', 'Birthday', 'Corporate', 'Anniversary', 'Festival',
];

final _searchResultsProvider = FutureProvider<List<Vendor>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  final cat = ref.watch(_filterCategoryProvider);
  final city = ref.watch(_filterCityProvider);
  ref.watch(_filterEventTypeProvider); // tracked for UI chips
  final minRating = ref.watch(_filterMinRatingProvider);
  final minPrice = ref.watch(_filterMinPriceProvider);
  final maxPrice = ref.watch(_filterMaxPriceProvider);
  final verifiedOnly = ref.watch(_filterVerifiedOnlyProvider);
  final hideFullyBooked = ref.watch(_filterHideFullyBookedProvider);
  final language = ref.watch(_filterLanguageProvider);
  final date = ref.watch(_filterDateProvider);
  final sort = ref.watch(_sortProvider);
  var list = await ref
      .watch(vendorRepoProvider)
      .list(category: cat, city: city, query: query);
  list = list.where((v) => v.ratingAvg >= minRating).toList();
  if (verifiedOnly) list = list.where((v) => v.isVerified).toList();
  if (hideFullyBooked) list = list.where((v) => !v.fullyBooked).toList();
  if (language != null) {
    list = list.where((v) => v.languages.contains(language)).toList();
  }
  if (minPrice > 0) {
    list = list.where((v) => (v.basePrice ?? 0) >= minPrice).toList();
  }
  if (maxPrice > 0) {
    list = list.where((v) => (v.basePrice ?? 0) <= maxPrice).toList();
  }
  if (date != null) {
    final blockedIds = await ref
        .watch(availabilityRepoProvider)
        .blockedVendorIdsOnDate(date);
    list = list.where((v) => !blockedIds.contains(v.id)).toList();
  }
  switch (sort) {
    case _SortOption.topRated:
      list.sort((a, b) => b.ratingAvg.compareTo(a.ratingAvg));
    case _SortOption.priceLow:
      list.sort((a, b) => (a.basePrice ?? 0).compareTo(b.basePrice ?? 0));
    case _SortOption.priceHigh:
      list.sort((a, b) => (b.basePrice ?? 0).compareTo(a.basePrice ?? 0));
    case _SortOption.featured:
      list.sort((a, b) {
        final af = a.isFeatured ? 0 : 1;
        final bf = b.isFeatured ? 0 : 1;
        return af.compareTo(bf);
      });
  }
  return list;
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(_searchResultsProvider);
    final cat = ref.watch(_filterCategoryProvider);
    final city = ref.watch(_filterCityProvider);
    final eventType = ref.watch(_filterEventTypeProvider);
    final minRating = ref.watch(_filterMinRatingProvider);
    final minPrice = ref.watch(_filterMinPriceProvider);
    final maxPrice = ref.watch(_filterMaxPriceProvider);
    final verifiedOnly = ref.watch(_filterVerifiedOnlyProvider);
    final filterDate = ref.watch(_filterDateProvider);
    final sort = ref.watch(_sortProvider);

    final hideFullyBooked = ref.watch(_filterHideFullyBookedProvider);
    final language = ref.watch(_filterLanguageProvider);
    final hasFilters = cat != null || city != null || eventType != null ||
        minRating > 0 || minPrice > 0 || maxPrice > 0 || verifiedOnly ||
        filterDate != null || hideFullyBooked || language != null;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search vendors, services...',
            border: InputBorder.none,
          ),
          onChanged: (v) =>
              ref.read(_searchQueryProvider.notifier).state = v,
        ),
        actions: [
          PopupMenuButton<_SortOption>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            initialValue: sort,
            onSelected: (v) => ref.read(_sortProvider.notifier).state = v,
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: _SortOption.topRated,
                  child: Text('Top Rated')),
              PopupMenuItem(
                  value: _SortOption.priceLow,
                  child: Text('Price: Low to High')),
              PopupMenuItem(
                  value: _SortOption.priceHigh,
                  child: Text('Price: High to Low')),
              PopupMenuItem(
                  value: _SortOption.featured,
                  child: Text('Featured First')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.tune,
                color: hasFilters ? AppColors.violet : null),
            onPressed: () => _showFilters(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (hasFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  if (cat != null)
                    Chip(
                      label: Text(cat),
                      onDeleted: () =>
                          ref.read(_filterCategoryProvider.notifier).state = null,
                    ),
                  if (city != null)
                    Chip(
                      label: Text(city),
                      onDeleted: () =>
                          ref.read(_filterCityProvider.notifier).state = null,
                    ),
                  if (minRating > 0)
                    Chip(
                      label: Text('${minRating.toStringAsFixed(1)}★+'),
                      onDeleted: () =>
                          ref.read(_filterMinRatingProvider.notifier).state = 0,
                    ),
                  if (eventType != null)
                    Chip(
                      label: Text(eventType),
                      onDeleted: () => ref
                          .read(_filterEventTypeProvider.notifier)
                          .state = null,
                    ),
                  if (minPrice > 0 || maxPrice > 0)
                    Chip(
                      label: Text(maxPrice > 0
                          ? '₹${minPrice.toInt()}–₹${maxPrice.toInt()}'
                          : '₹${minPrice.toInt()}+'),
                      onDeleted: () {
                        ref.read(_filterMinPriceProvider.notifier).state = 0;
                        ref.read(_filterMaxPriceProvider.notifier).state = 0;
                      },
                    ),
                  if (verifiedOnly)
                    Chip(
                      avatar: const Icon(Icons.verified, size: 14),
                      label: const Text('Verified only'),
                      onDeleted: () => ref
                          .read(_filterVerifiedOnlyProvider.notifier)
                          .state = false,
                    ),
                  if (filterDate != null)
                    Chip(
                      avatar: const Icon(Icons.event_available_rounded,
                          size: 14),
                      label: Text(
                          '${filterDate.day}/${filterDate.month}/${filterDate.year}'),
                      onDeleted: () => ref
                          .read(_filterDateProvider.notifier)
                          .state = null,
                    ),
                ],
              ),
            ),
          Expanded(
            child: results.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(16),
                children: List.generate(6, (_) => const SkeletonCard()),
              ),
              error: (e, _) => ErrorView(
                error: e,
                onRetry: () => ref.invalidate(_searchResultsProvider),
              ),
              data: (list) => list.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'No vendors found',
                      subtitle: 'Try different filters or keywords',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ResultCard(vendor: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Consumer(builder: (ctx, ref, child) {
        final cats = ref.watch(categoriesProvider);
        final cities = ref.watch(citiesProvider);
        final minRating = ref.watch(_filterMinRatingProvider);
        final minPrice = ref.watch(_filterMinPriceProvider);
        final maxPrice = ref.watch(_filterMaxPriceProvider);
        final selEventType = ref.watch(_filterEventTypeProvider);
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Event type
              const Text('Event Type',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _eventTypes
                    .map((t) => FilterChip(
                          label: Text(t),
                          selected: selEventType == t,
                          onSelected: (s) => ref
                              .read(_filterEventTypeProvider.notifier)
                              .state = s ? t : null,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              // Budget range
              const Text('Budget Range',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              RangeSlider(
                values: RangeValues(minPrice, maxPrice > 0 ? maxPrice : 200000),
                min: 0,
                max: 200000,
                divisions: 40,
                labels: RangeLabels(
                  minPrice > 0 ? '₹${(minPrice / 1000).toStringAsFixed(0)}K' : 'Any',
                  maxPrice > 0 ? '₹${(maxPrice / 1000).toStringAsFixed(0)}K' : 'Any',
                ),
                activeColor: AppColors.violet,
                onChanged: (r) {
                  ref.read(_filterMinPriceProvider.notifier).state = r.start;
                  ref.read(_filterMaxPriceProvider.notifier).state =
                      r.end >= 200000 ? 0 : r.end;
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    minPrice > 0 ? '₹${minPrice.toInt()}' : 'No min',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                  Text(
                    maxPrice > 0 ? '₹${maxPrice.toInt()}' : 'No max',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              cats.maybeWhen(
                data: (list) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: list
                      .map((c) => FilterChip(
                            label: Text(c.name),
                            selected:
                                ref.watch(_filterCategoryProvider) == c.slug,
                            onSelected: (s) => ref
                                .read(_filterCategoryProvider.notifier)
                                .state = s ? c.slug : null,
                          ))
                      .toList(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              const Text('City', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              cities.maybeWhen(
                data: (list) => Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: list
                      .map((c) => FilterChip(
                            label: Text(c.name),
                            selected: ref.watch(_filterCityProvider) == c.name,
                            onSelected: (s) => ref
                                .read(_filterCityProvider.notifier)
                                .state = s ? c.name : null,
                          ))
                      .toList(),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Text('Min rating: ${minRating.toStringAsFixed(1)}★',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Slider(
                value: minRating,
                onChanged: (v) =>
                    ref.read(_filterMinRatingProvider.notifier).state = v,
                min: 0,
                max: 5,
                divisions: 10,
                label: minRating.toStringAsFixed(1),
                activeColor: AppColors.violet,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Verified vendors only',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle:
                    const Text('Show only platform-verified vendors'),
                value: ref.watch(_filterVerifiedOnlyProvider),
                activeThumbColor: AppColors.violet,
                onChanged: (v) => ref
                    .read(_filterVerifiedOnlyProvider.notifier)
                    .state = v,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide fully booked vendors',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Only show vendors accepting bookings'),
                value: ref.watch(_filterHideFullyBookedProvider),
                activeThumbColor: AppColors.violet,
                onChanged: (v) => ref
                    .read(_filterHideFullyBookedProvider.notifier)
                    .state = v,
              ),
              const SizedBox(height: 8),
              const Text('Language',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Hindi', 'English', 'Gujarati', 'Marathi', 'Punjabi', 'Urdu']
                    .map((lang) {
                  final sel = ref.watch(_filterLanguageProvider) == lang;
                  return FilterChip(
                    label: Text(lang),
                    selected: sel,
                    selectedColor: AppColors.violet.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.violet,
                    onSelected: (v) => ref
                        .read(_filterLanguageProvider.notifier)
                        .state = v ? lang : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Available on Date',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Builder(builder: (ctx) {
                final selDate = ref.watch(_filterDateProvider);
                return OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text(selDate == null
                      ? 'Pick a date'
                      : '${selDate.day}/${selDate.month}/${selDate.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      ref.read(_filterDateProvider.notifier).state = picked;
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: selDate != null ? AppColors.violet : null,
                    side: selDate != null
                        ? const BorderSide(color: AppColors.violet)
                        : null,
                  ),
                );
              }),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(_filterCategoryProvider.notifier).state = null;
                      ref.read(_filterCityProvider.notifier).state = null;
                      ref.read(_filterEventTypeProvider.notifier).state = null;
                      ref.read(_filterMinRatingProvider.notifier).state = 0;
                      ref.read(_filterMinPriceProvider.notifier).state = 0;
                      ref.read(_filterMaxPriceProvider.notifier).state = 0;
                      ref.read(_filterVerifiedOnlyProvider.notifier).state = false;
                      ref.read(_filterHideFullyBookedProvider.notifier).state = false;
                      ref.read(_filterLanguageProvider.notifier).state = null;
                      ref.read(_filterDateProvider.notifier).state = null;
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Apply'),
                  ),
                ),
              ]),
            ],
          ),
        );
      }),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/vendor-detail/${vendor.id}', extra: vendor),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: vendor.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: vendor.avatarUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                              width: 64, height: 64, color: AppColors.violetMid),
                        )
                      : Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                              gradient: AppColors.brandGradient),
                          alignment: Alignment.center,
                          child: Text(
                            (vendor.name ?? 'V')[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                ),
                if (vendor.isFeatured)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.violetDeep, AppColors.violet],
                        ),
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: const Text('FEATURED',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(vendor.name ?? 'Vendor',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                    ),
                    if (vendor.isVerified)
                      const Tooltip(
                        message: 'Verified vendor',
                        child: Icon(Icons.verified,
                            color: Colors.blue, size: 16),
                      ),
                    if (vendor.fullyBooked)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Full',
                            style: TextStyle(
                                color: AppColors.danger,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(
                      '${vendor.category}${vendor.city != null ? ' · ${vendor.city}' : ''}',
                      style: const TextStyle(
                          color: AppColors.slate, fontSize: 13)),
                  if (vendor.tagline != null &&
                      vendor.tagline!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        vendor.tagline!,
                        style: const TextStyle(
                            color: AppColors.violet,
                            fontSize: 11,
                            fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 14),
                    Text(' ${vendor.ratingAvg.toStringAsFixed(1)}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    if (vendor.eventsCount > 0) ...[
                      const SizedBox(width: 8),
                      Text('${vendor.eventsCount} events',
                          style: const TextStyle(
                              color: AppColors.slate, fontSize: 11)),
                    ],
                    if (vendor.basePrice != null) ...[
                      const Spacer(),
                      Text(Fmt.currency(vendor.basePrice!),
                          style: const TextStyle(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ],
                  ]),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
          ]),
        ),
      ),
    );
  }
}
