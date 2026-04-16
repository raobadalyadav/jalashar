import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/models/vendor_meta.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import 'compare_vendors_screen.dart';

class VendorDetailScreen extends ConsumerStatefulWidget {
  const VendorDetailScreen({super.key, required this.vendor});
  final Vendor vendor;

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    _trackView();
  }

  Future<void> _trackView() async {
    await ref.read(vendorRepoProvider).incrementProfileViews(widget.vendor.id);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callVendor() async {
    final phone = widget.vendor.phone;
    if (phone == null || phone.isEmpty) return;
    await _launchUrl('tel:$phone');
  }

  Future<void> _whatsappVendor() async {
    final number = (widget.vendor.whatsapp?.isNotEmpty == true)
        ? widget.vendor.whatsapp!
        : widget.vendor.phone ?? '';
    if (number.isEmpty) return;
    final clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    await _launchUrl('https://wa.me/$clean');
  }

  Future<void> _shareProfile() async {
    final name = widget.vendor.name ?? 'Vendor';
    final category = widget.vendor.category;
    await Share.share(
      'Check out $name ($category) on Jalashar!\nhttps://jalashar.in/vendor/${widget.vendor.id}',
    );
  }

  Future<void> _reportVendor() async {
    final reasons = [
      'Fake profile',
      'Inappropriate content',
      'Wrong information',
      'Rude behavior',
      'No-show / scam',
      'Other',
    ];
    String? selectedReason;
    final descCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => Container(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Report Vendor',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Help us keep the platform safe',
                  style: TextStyle(color: AppColors.slate, fontSize: 13)),
              const SizedBox(height: 16),
              ...reasons.map((r) => RadioListTile<String>(
                    value: r,
                    groupValue: selectedReason,
                    title: Text(r),
                    activeColor: AppColors.violet,
                    onChanged: (v) => setSt(() => selectedReason = v),
                    dense: true,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                  hintText: 'Describe what happened',
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.danger),
                    onPressed: selectedReason == null
                        ? null
                        : () async {
                            await ref.read(reportRepoProvider).submit(
                                  vendorId: widget.vendor.id,
                                  reason: selectedReason!,
                                  description: descCtrl.text.trim(),
                                );
                            descCtrl.dispose();
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Report submitted. Thank you.')),
                              );
                            }
                          },
                    child: const Text('Submit Report'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadSaved() async {
    final s = await ref.read(wishlistRepoProvider).isSaved(widget.vendor.id);
    if (mounted) setState(() => _saved = s);
  }

  Future<void> _openChat() async {
    final bookings = await ref.read(myBookingsProvider.future);
    if (!mounted) return;
    final booking =
        bookings.where((b) => b.vendorId == widget.vendor.id).firstOrNull;
    if (booking != null) {
      context.push('/chat/${booking.id}/${widget.vendor.userId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book this vendor first to start chatting'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleWishlist() async {
    await ref.read(wishlistRepoProvider).toggle(widget.vendor.id);
    if (mounted) {
      setState(() => _saved = !_saved);
      ref.invalidate(wishlistProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = widget.vendor;
    final reviews = ref.watch(vendorReviewsProvider(vendor.id));
    final packages = ref.watch(vendorPackagesProvider(vendor.id));
    final blockedDates = ref.watch(
      FutureProvider.autoDispose<Set<DateTime>>((r) =>
          r.watch(availabilityRepoProvider).blockedDates(vendor.id)).future,
    );
    final inCompare = ref.watch(
        compareVendorsProvider.select((l) => l.any((v) => v.id == vendor.id)));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero AppBar ──────────────────────────────────────────────────
          SliverAppBar.large(
            expandedHeight: 280,
            pinned: true,
            actions: [
              IconButton(
                tooltip: 'Share profile',
                onPressed: _shareProfile,
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton(
                tooltip:
                    inCompare ? 'Remove from compare' : 'Add to compare',
                onPressed: () {
                  ref.read(compareVendorsProvider.notifier).toggle(vendor);
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
                  color: inCompare ? AppColors.violet : null,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'wishlist') _toggleWishlist();
                  if (v == 'report') _reportVendor();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'wishlist',
                    child: Row(children: [
                      Icon(_saved ? Icons.favorite : Icons.favorite_border,
                          color: _saved ? Colors.red : null, size: 18),
                      const SizedBox(width: 10),
                      Text(_saved ? 'Remove from Wishlist' : 'Save to Wishlist'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(children: [
                      Icon(Icons.flag_outlined, color: AppColors.danger, size: 18),
                      SizedBox(width: 10),
                      Text('Report Vendor',
                          style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(vendor.name ?? 'Vendor'),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (vendor.portfolioUrls.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: vendor.portfolioUrls.first,
                      fit: BoxFit.cover,
                      errorWidget: (c, u, e) => Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient),
                      ),
                    )
                  else if (vendor.avatarUrl != null)
                    CachedNetworkImage(
                        imageUrl: vendor.avatarUrl!, fit: BoxFit.cover)
                  else
                    Container(
                        decoration: const BoxDecoration(
                            gradient: AppColors.heroGradient)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Rating + tags ──────────────────────────────────────
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
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
                  ]).animate().fadeIn(),

                  const SizedBox(height: 12),

                  if (vendor.basePrice != null)
                    Text(
                      '${Fmt.currency(vendor.basePrice!)} onwards',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w800),
                    ).animate().fadeIn(delay: 80.ms),

                  const SizedBox(height: 20),

                  // ── Fully Booked Banner ────────────────────────────────
                  if (vendor.fullyBooked) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.event_busy_rounded,
                            color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This vendor is fully booked at the moment. Check back later or contact them directly.',
                            style: TextStyle(
                                color: AppColors.danger, fontSize: 13),
                          ),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 90.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── Stats Row ──────────────────────────────────────────
                  if (vendor.yearsExperience > 0 ||
                      vendor.eventsCount > 0 ||
                      vendor.profileViews > 0) ...[
                    Row(children: [
                      if (vendor.yearsExperience > 0)
                        _StatChip(
                          icon: Icons.workspace_premium_outlined,
                          label: '${vendor.yearsExperience}+ yrs',
                        ),
                      if (vendor.eventsCount > 0) ...[
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.celebration_outlined,
                          label: '${vendor.eventsCount} events',
                        ),
                      ],
                      if (vendor.profileViews > 0) ...[
                        const SizedBox(width: 8),
                        _StatChip(
                          icon: Icons.visibility_outlined,
                          label: '${vendor.profileViews} views',
                        ),
                      ],
                    ]).animate().fadeIn(delay: 95.ms),
                    const SizedBox(height: 16),
                  ],

                  // ── About ──────────────────────────────────────────────
                  _SectionHeader(
                      title: 'About',
                      icon: Icons.person_outline_rounded),
                  const SizedBox(height: 8),
                  if (vendor.tagline != null && vendor.tagline!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '"${vendor.tagline}"',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.violet,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  Text(
                    vendor.bio ?? 'No description available.',
                    style: const TextStyle(height: 1.6),
                  ).animate().fadeIn(delay: 100.ms),

                  // ── Contact ────────────────────────────────────────────
                  if ((vendor.phone?.isNotEmpty == true) ||
                      (vendor.whatsapp?.isNotEmpty == true)) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                        title: 'Contact',
                        icon: Icons.contacts_outlined),
                    const SizedBox(height: 10),
                    Row(children: [
                      if (vendor.phone?.isNotEmpty == true)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _callVendor,
                            icon: const Icon(Icons.phone_outlined, size: 18),
                            label: Text(vendor.phone!),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.success,
                              side: const BorderSide(
                                  color: AppColors.success, width: 1.2),
                            ),
                          ),
                        ),
                      if (vendor.phone?.isNotEmpty == true &&
                          (vendor.whatsapp?.isNotEmpty == true ||
                              vendor.phone?.isNotEmpty == true))
                        const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _whatsappVendor,
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(
                                color: Color(0xFF25D366), width: 1.2),
                          ),
                        ),
                      ),
                    ]).animate().fadeIn(delay: 110.ms),
                  ],

                  // ── Social Links ───────────────────────────────────────
                  if ((vendor.instagramUrl?.isNotEmpty == true) ||
                      (vendor.youtubeUrl?.isNotEmpty == true) ||
                      (vendor.facebookUrl?.isNotEmpty == true)) ...[
                    const SizedBox(height: 16),
                    Row(children: [
                      const Text('Find us on:',
                          style: TextStyle(
                              color: AppColors.slate, fontSize: 13)),
                      const SizedBox(width: 12),
                      if (vendor.instagramUrl?.isNotEmpty == true)
                        _SocialIconButton(
                          icon: Icons.camera_alt_outlined,
                          color: const Color(0xFFE1306C),
                          tooltip: 'Instagram',
                          onTap: () => _launchUrl(vendor.instagramUrl!),
                        ),
                      if (vendor.youtubeUrl?.isNotEmpty == true)
                        _SocialIconButton(
                          icon: Icons.play_circle_outline_rounded,
                          color: const Color(0xFFFF0000),
                          tooltip: 'YouTube',
                          onTap: () => _launchUrl(vendor.youtubeUrl!),
                        ),
                      if (vendor.facebookUrl?.isNotEmpty == true)
                        _SocialIconButton(
                          icon: Icons.facebook_outlined,
                          color: const Color(0xFF1877F2),
                          tooltip: 'Facebook',
                          onTap: () => _launchUrl(vendor.facebookUrl!),
                        ),
                    ]).animate().fadeIn(delay: 115.ms),
                  ],

                  // ── Service Cities ─────────────────────────────────────
                  if (vendor.serviceCities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _SectionHeader(
                        title: 'Service Areas',
                        icon: Icons.map_outlined),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: vendor.serviceCities
                          .map((city) => Chip(
                                avatar: const Icon(Icons.location_on,
                                    size: 14, color: AppColors.violet),
                                label: Text(city),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ).animate().fadeIn(delay: 120.ms),
                  ],

                  // ── Specializations ────────────────────────────────────
                  if (vendor.meta.isNotEmpty &&
                      VendorCategoryMeta.hasFields(vendor.category)) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                        title: 'Specializations',
                        icon: Icons.auto_awesome_rounded),
                    const SizedBox(height: 10),
                    _SpecializationsView(vendor: vendor),
                  ],

                  // ── Packages & Pricing ─────────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader(
                      title: 'Packages & Pricing',
                      icon: Icons.inventory_2_outlined),
                  const SizedBox(height: 10),
                  packages.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => const Text('Could not load packages'),
                    data: (list) => list.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.softSurface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: AppColors.violet, size: 18),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Contact vendor directly for detailed pricing',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ]),
                          )
                        : _PackagesView(packages: list),
                  ),

                  // ── Portfolio ──────────────────────────────────────────
                  if (vendor.portfolioUrls.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                        title: 'Portfolio',
                        icon: Icons.photo_library_outlined),
                    const SizedBox(height: 10),
                    _PortfolioGrid(urls: vendor.portfolioUrls),
                  ],

                  // ── Availability ───────────────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader(
                      title: 'Availability (Next 21 days)',
                      icon: Icons.calendar_month_outlined),
                  const SizedBox(height: 8),
                  FutureBuilder<Set<DateTime>>(
                    future: blockedDates,
                    builder: (_, snap) => _MiniAvailabilityCalendar(
                        blockedDates: snap.data ?? {}),
                  ),

                  // ── Reviews ────────────────────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader(
                      title: 'Reviews',
                      icon: Icons.rate_review_outlined),
                  const SizedBox(height: 8),
                  reviews.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Text('Error: $e'),
                    data: (list) => list.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('No reviews yet',
                                style: TextStyle(color: AppColors.slate)),
                          )
                        : Column(
                            children: list
                                .asMap()
                                .entries
                                .map((e) => _ReviewCard(review: e.value)
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds: e.key * 60)))
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
                onPressed: _openChat,
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Message'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push('/booking/new', extra: vendor),
                icon: const Icon(Icons.event_available),
                label: const Text('Book Now — Free'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.softSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: AppColors.violet),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.charcoal)),
      ]),
    );
  }
}

// ── Social Icon Button ────────────────────────────────────────────────────────

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton(
      {required this.icon,
      required this.color,
      required this.tooltip,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, color: AppColors.violet, size: 20),
      const SizedBox(width: 8),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}

// ── Specializations View ──────────────────────────────────────────────────────

class _SpecializationsView extends StatelessWidget {
  const _SpecializationsView({required this.vendor});
  final Vendor vendor;

  @override
  Widget build(BuildContext context) {
    final fields = VendorCategoryMeta.forCategory(vendor.category);
    final items = <Widget>[];

    for (final field in fields) {
      final value = vendor.meta[field.key];
      if (value == null) continue;
      if (field.type == MetaFieldType.multiselect &&
          value is List &&
          value.isNotEmpty) {
        items.add(_MetaChipRow(
            label: field.label, values: value.cast<String>()));
      } else if (field.type != MetaFieldType.multiselect &&
          value.toString().isNotEmpty) {
        items.add(_MetaTextRow(
            label: field.label, value: value.toString()));
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: context.softSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: items
              .map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: w,
                  ))
              .toList(),
        ),
      ),
    ).animate().fadeIn(delay: 120.ms);
  }
}

class _MetaChipRow extends StatelessWidget {
  const _MetaChipRow({required this.label, required this.values});
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.slate)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values
              .map((v) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(v,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.violet,
                            fontWeight: FontWeight.w500)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _MetaTextRow extends StatelessWidget {
  const _MetaTextRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.slate)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}

// ── Packages View ─────────────────────────────────────────────────────────────

class _PackagesView extends StatelessWidget {
  const _PackagesView({required this.packages});
  final List<VendorPackage> packages;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<VendorPackage>>{};
    for (final p in packages) {
      grouped.putIfAbsent(p.eventType ?? 'General', () => []).add(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          Row(children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.violet, AppColors.violetDeep]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(entry.key,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Divider(color: AppColors.violetMid)),
          ]),
          const SizedBox(height: 8),
          ...entry.value.asMap().entries.map(
                (e) => _PackageCard(pkg: e.value)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: e.key * 60))
                    .slideX(begin: 0.04),
              ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.pkg});
  final VendorPackage pkg;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pkg.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (pkg.durationHours != null)
                    Text('${pkg.durationHours}h coverage',
                        style: const TextStyle(
                            color: AppColors.slate, fontSize: 12)),
                  if (pkg.features.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pkg.features
                          .map((f) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppColors.success,
                                        size: 13),
                                    const SizedBox(width: 4),
                                    Text(f,
                                        style: const TextStyle(
                                            fontSize: 12)),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(Fmt.currency(pkg.price),
                    style: const TextStyle(
                        color: AppColors.violet,
                        fontWeight: FontWeight.w800,
                        fontSize: 17)),
                const Text('onwards',
                    style: TextStyle(
                        fontSize: 10, color: AppColors.slate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Portfolio Grid with Lightbox ──────────────────────────────────────────────

class _PortfolioGrid extends StatelessWidget {
  const _PortfolioGrid({required this.urls});
  final List<String> urls;

  void _openLightbox(BuildContext context, int initialIndex) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (ctx, a, b) =>
          _LightboxView(urls: urls, initialIndex: initialIndex),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: urls.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _openLightbox(context, i),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: urls[i],
            fit: BoxFit.cover,
            placeholder: (c, u) =>
                Container(color: c.softSurface),
            errorWidget: (c, u, e) => Container(
              color: c.softSurface,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.slate),
            ),
          ),
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: i * 40)),
    );
  }
}

class _LightboxView extends StatefulWidget {
  const _LightboxView({required this.urls, required this.initialIndex});
  final List<String> urls;
  final int initialIndex;

  @override
  State<_LightboxView> createState() => _LightboxViewState();
}

class _LightboxViewState extends State<_LightboxView> {
  late final PageController _controller;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.urls.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: widget.urls[i],
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_current + 1} / ${widget.urls.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Availability Calendar ─────────────────────────────────────────────────────

class _MiniAvailabilityCalendar extends StatelessWidget {
  const _MiniAvailabilityCalendar({required this.blockedDates});
  final Set<DateTime> blockedDates;

  bool _isBlocked(DateTime day) => blockedDates.any(
      (d) => d.year == day.year && d.month == day.month && d.day == day.day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days =
        List.generate(21, (i) => DateTime.now().add(Duration(days: i)));

    return Card(
      elevation: 0,
      color: context.softSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.circle, size: 10, color: AppColors.success),
              const SizedBox(width: 4),
              const Text('Available', style: TextStyle(fontSize: 11)),
              const SizedBox(width: 14),
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
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : (isToday
                            ? AppColors.violet.withValues(alpha: 0.15)
                            : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isToday
                          ? AppColors.violet
                          : blocked
                              ? AppColors.danger.withValues(alpha: 0.5)
                              : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: blocked
                          ? AppColors.danger
                          : AppColors.charcoal,
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

// ── Review Card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  gradient: AppColors.brandGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  (review.clientName?.isNotEmpty == true)
                      ? review.clientName![0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(review.clientName ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
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
            if (review.comment != null &&
                review.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment!,
                  style: const TextStyle(
                      height: 1.5, color: AppColors.charcoal)),
            ],
            const SizedBox(height: 4),
            Text(Fmt.date(review.createdAt),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.slate)),
          ],
        ),
      ),
    );
  }
}
