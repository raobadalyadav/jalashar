import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text('home.greeting'.tr()),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(14),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'home.search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _HeroBanner()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('home.categories'.tr(),
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          const SliverToBoxAdapter(child: _CategoryRow()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('Packages',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          services.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator()))),
            error: (e, _) => SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
            data: (list) => SliverList.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _ServiceCard(service: list[i]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.saffron, AppColors.deepMaroon],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'home.banner_title',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ).tr(),
          const SizedBox(height: 6),
          const Text('home.banner_sub', style: TextStyle(color: Colors.white70)).tr(),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.deepMaroon,
              minimumSize: const Size(140, 44),
            ),
            onPressed: () {},
            child: const Text('home.book_now').tr(),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('home.cat_wedding', Icons.favorite),
      ('home.cat_birthday', Icons.cake),
      ('home.cat_corporate', Icons.business_center),
      ('home.cat_engagement', Icons.diamond),
      ('home.cat_festival', Icons.celebration),
    ];
    return SizedBox(
      height: 100,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, i) {
          final (key, icon) = items[i];
          return Container(
            width: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.ivory,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.deepMaroon, size: 30),
                const SizedBox(height: 8),
                Text(key.tr(), style: const TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final ServicePackage service;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/service/${service.slug}', extra: service),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.celebration,
                      color: AppColors.deepMaroon, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(service.planningDuration ?? '',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(Fmt.currency(service.basePrice),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.deepMaroon)),
              ]),
              if (service.features.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: service.features
                      .take(4)
                      .map((f) => Chip(
                            label: Text(f, style: const TextStyle(fontSize: 11)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
