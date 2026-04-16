import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

final _searchQueryProvider = StateProvider<String>((_) => '');
final _filterCategoryProvider = StateProvider<String?>((_) => null);
final _filterCityProvider = StateProvider<String?>((_) => null);
final _filterMinRatingProvider = StateProvider<double>((_) => 0);

final _searchResultsProvider = FutureProvider<List<Vendor>>((ref) async {
  final query = ref.watch(_searchQueryProvider);
  final cat = ref.watch(_filterCategoryProvider);
  final city = ref.watch(_filterCityProvider);
  final minRating = ref.watch(_filterMinRatingProvider);
  final list = await ref
      .watch(vendorRepoProvider)
      .list(category: cat, city: city, query: query);
  return list.where((v) => v.ratingAvg >= minRating).toList();
});

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(_searchResultsProvider);
    final cat = ref.watch(_filterCategoryProvider);
    final city = ref.watch(_filterCityProvider);
    final minRating = ref.watch(_filterMinRatingProvider);

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
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilters(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          if (cat != null || city != null || minRating > 0)
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
      builder: (_) => Consumer(builder: (_, ref, __) {
        final cats = ref.watch(categoriesProvider);
        final cities = ref.watch(citiesProvider);
        final minRating = ref.watch(_filterMinRatingProvider);
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
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
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(_filterCategoryProvider.notifier).state = null;
                      ref.read(_filterCityProvider.notifier).state = null;
                      ref.read(_filterMinRatingProvider.notifier).state = 0;
                    },
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.ivory,
          child: Icon(Icons.storefront, color: AppColors.deepMaroon),
        ),
        title: Text(vendor.name ?? 'Vendor'),
        subtitle: Text('${vendor.category} · ${vendor.city ?? ""}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.star, color: AppColors.gold, size: 14),
              Text(' ${vendor.ratingAvg.toStringAsFixed(1)}'),
            ]),
            if (vendor.basePrice != null)
              Text(Fmt.currency(vendor.basePrice!),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        onTap: () => context.push('/vendor-detail/${vendor.id}', extra: vendor),
      ),
    );
  }
}
