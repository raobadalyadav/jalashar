import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/content_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/extra_models.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// Featured vendors from top-rated list
final _featuredVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final list = await ref.watch(vendorRepoProvider).list();
  return list.where((v) => v.isFeatured || v.ratingAvg >= 4.5).take(8).toList();
});

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(servicesProvider);
    final categories = ref.watch(categoriesProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = context.isDark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            titleSpacing: 16,
            title: user.when(
              data: (u) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : AppColors.slate,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    u?.name != null ? u!.name! : 'home.greeting'.tr(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              loading: () => Text('home.greeting'.tr()),
              error: (e, st) => Text('home.greeting'.tr()),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),

          // ── Search bar ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: InkWell(
                onTap: () => context.push('/search'),
                borderRadius: BorderRadius.circular(14),
                child: AbsorbPointer(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'home.search_hint'.tr(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Container(
                        margin: const EdgeInsets.all(6),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.violet,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Event type quick pickers ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _eventTypes.map((e) {
                    return GestureDetector(
                      onTap: () =>
                          context.push('/search?eventType=${e.$1}'),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.violet, AppColors.violetDeep],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.violet.withValues(alpha: 0.25),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.$2, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              e.$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ).animate().fadeIn(delay: 50.ms),
          ),

          // ── Banner carousel ───────────────────────────────────────────
          const SliverToBoxAdapter(child: _BannerCarousel()),

          // ── Featured Vendors ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Featured Vendors',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Top-rated & trusted professionals',
                          style: TextStyle(
                              color: AppColors.slate, fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('See All'),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer(
              builder: (ctx, ref, child) {
                final vendors = ref.watch(_featuredVendorsProvider);
                return vendors.when(
                  loading: () => SizedBox(
                    height: 190,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: 4,
                      separatorBuilder: (c, i) =>
                          const SizedBox(width: 12),
                      itemBuilder: (c, i) =>
                          const _VendorCardSkeleton(),
                    ),
                  ),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : SizedBox(
                          height: 190,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: list.length,
                            separatorBuilder: (c, i) =>
                                const SizedBox(width: 12),
                            itemBuilder: (_, i) =>
                                _FeaturedVendorCard(v: list[i]),
                          ),
                        ),
                );
              },
            ),
          ),

          // ── Categories ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                Expanded(
                  child: Text('home.categories'.tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('Browse All'),
                ),
              ]),
            ),
          ),
          SliverToBoxAdapter(
            child: categories.when(
              loading: () => const _CategoryRow(items: []),
              error: (e, st) => const _CategoryRow(items: []),
              data: (cats) => _CategoryRow(
                items: cats
                    .map((c) => (c.name, c.slug, _categoryIcon(c.slug)))
                    .toList(),
              ),
            ),
          ),

          // ── Quick Tools ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Planning Tools',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: _QuickToolCard(
                        icon: Icons.calculate_outlined,
                        title: 'Budget\nEstimator',
                        subtitle: 'Plan your event cost',
                        color: AppColors.violet,
                        onTap: () =>
                            context.push('/budget-estimator'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickToolCard(
                        icon: Icons.compare_arrows_rounded,
                        title: 'Compare\nVendors',
                        subtitle: 'Side-by-side view',
                        color: AppColors.gold,
                        onTap: () => context.push('/compare'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),

          // ── Packages ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
                const Expanded(
                  child: Text('Packages',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => context.push('/search'),
                  child: const Text('See All'),
                ),
              ]),
            ),
          ),
          services.when(
            loading: () => const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator()))),
            error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: $e'))),
            data: (list) => SliverList.builder(
              itemCount: list.length,
              itemBuilder: (_, i) => _ServiceCard(service: list[i]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  static String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  static const _eventTypes = [
    ('Wedding', '💍'),
    ('Birthday', '🎂'),
    ('Corporate', '💼'),
    ('Engagement', '💞'),
    ('Anniversary', '🎊'),
    ('Festival', '🎉'),
  ];

  static IconData _categoryIcon(String slug) => switch (slug) {
        'photographer' => Icons.camera_alt,
        'makeup' => Icons.brush,
        'dj' => Icons.music_note,
        'caterer' => Icons.restaurant,
        'decorator' => Icons.celebration,
        'mehendi' => Icons.pan_tool,
        'pandit' => Icons.temple_hindu,
        'florist' => Icons.local_florist,
        'videographer' => Icons.videocam,
        'band' => Icons.queue_music,
        _ => Icons.storefront,
      };
}

// ── Featured vendor card ─────────────────────────────────────────────────────

class _FeaturedVendorCard extends StatelessWidget {
  const _FeaturedVendorCard({required this.v});
  final Vendor v;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendor-detail/${v.id}', extra: v),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image / avatar
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  v.portfolioUrls.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: v.portfolioUrls.first,
                          width: 150,
                          height: 100,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) =>
                              _VendorImgFallback(name: v.name ?? v.category),
                        )
                      : _VendorImgFallback(name: v.name ?? v.category),
                  // Featured badge
                  if (v.isFeatured)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('⭐ Featured',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  // Verified badge
                  if (v.isVerified)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.verified,
                            color: Colors.white, size: 10),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.name ?? v.category,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    v.category,
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.gold, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      v.ratingAvg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const Spacer(),
                    if (v.basePrice != null)
                      Text(
                        '₹${(v.basePrice! / 1000).toStringAsFixed(0)}k+',
                        style: const TextStyle(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
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

class _VendorImgFallback extends StatelessWidget {
  const _VendorImgFallback({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 100,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.violetDeep, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'V',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _VendorCardSkeleton extends StatelessWidget {
  const _VendorCardSkeleton();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: context.softSurface,
        borderRadius: BorderRadius.circular(16),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: AppColors.violet.withValues(alpha: 0.1));
  }
}

// ── Banner Carousel ──────────────────────────────────────────────────────────

class _BannerCarousel extends ConsumerStatefulWidget {
  const _BannerCarousel();
  @override
  ConsumerState<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<_BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoScroll(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % count;
      _controller.animateToPage(next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider);
    return banners.when(
      loading: () => _StaticBanner(),
      error: (e, st) => _StaticBanner(),
      data: (list) {
        if (list.isEmpty) return _StaticBanner();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _startAutoScroll(list.length));
        return Column(
          children: [
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _controller,
                itemCount: list.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _BannerItem(banner: list[i]),
              ),
            ),
            if (list.length > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  list.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _current == i ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _current == i
                          ? AppColors.violet
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _BannerItem extends StatelessWidget {
  const _BannerItem({required this.banner});
  final Banner banner;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (banner.imageUrl != null)
            CachedNetworkImage(
              imageUrl: banner.imageUrl!,
              fit: BoxFit.cover,
              errorWidget: (c, u, e) => _GradientBg(),
            )
          else
            _GradientBg(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 20,
            right: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientBg extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.violetDeep],
        ),
      ),
    );
  }
}

class _StaticBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(24),
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.violetDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
          const Text('home.banner_sub',
                  style: TextStyle(color: Colors.white70))
              .tr(),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.violetDeep,
              minimumSize: const Size(140, 44),
            ),
            onPressed: () => context.push('/search'),
            child: const Text('home.book_now').tr(),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}

// ── Category Row ─────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.items});
  final List<(String, String, IconData)> items;

  static const _fallback = [
    ('Wedding', 'wedding', Icons.favorite),
    ('Birthday', 'birthday', Icons.cake),
    ('Corporate', 'corporate', Icons.business_center),
    ('Engagement', 'engagement', Icons.diamond),
    ('Festival', 'festival', Icons.celebration),
    ('Mehendi', 'mehendi', Icons.pan_tool),
  ];

  @override
  Widget build(BuildContext context) {
    final display = items.isNotEmpty ? items : _fallback;
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: display.length,
        separatorBuilder: (c, i) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final (label, slug, icon) = display[i];
          return InkWell(
            onTap: () => context.push('/search?category=$slug'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 78,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                // Use theme-aware color instead of hard-coded violetSoft
                color: context.softSurface,
                border: Border.all(
                    color: AppColors.violet.withValues(alpha: 0.15)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(icon, color: AppColors.violet, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: context.onSoftSurface),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Quick Tool Card ───────────────────────────────────────────────────────────

class _QuickToolCard extends StatelessWidget {
  const _QuickToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              Color.fromARGB(
                255,
                (color.r * 0.7).round(),
                (color.g * 0.7).round(),
                (color.b * 0.7).round(),
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.2)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 60.ms);
  }
}

// ── Service fallback icon ─────────────────────────────────────────────────────

class _ServiceIconFallback extends StatelessWidget {
  const _ServiceIconFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'S';
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.violet, AppColors.violetDeep],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Service Card ─────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service});
  final ServicePackage service;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/service/${service.slug}', extra: service),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: service.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: service.imageUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) =>
                          _ServiceIconFallback(name: service.name),
                    )
                  : _ServiceIconFallback(name: service.name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  if (service.planningDuration != null)
                    Text(service.planningDuration!,
                        style: Theme.of(context).textTheme.bodySmall),
                  if (service.features.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: service.features.take(3).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.softSurface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(f,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: context.onSoftSurface)),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.currency(service.basePrice),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.violet,
                        fontSize: 15)),
                const Text('onwards',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.slate)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.violet,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Book',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
