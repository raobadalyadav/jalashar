import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// Global compare list — max 3 vendors
final compareVendorsProvider =
    StateNotifierProvider<_CompareNotifier, List<Vendor>>(
        (_) => _CompareNotifier());

class _CompareNotifier extends StateNotifier<List<Vendor>> {
  _CompareNotifier() : super([]);

  void toggle(Vendor v) {
    if (state.any((x) => x.id == v.id)) {
      state = state.where((x) => x.id != v.id).toList();
    } else if (state.length < 3) {
      state = [...state, v];
    }
  }

  bool contains(String id) => state.any((v) => v.id == id);
  void clear() => state = [];
}

class CompareVendorsScreen extends ConsumerWidget {
  const CompareVendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(compareVendorsProvider);

    if (vendors.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Compare Vendors')),
        body: const Center(
          child: Text('No vendors selected for comparison.\nGo to Explore and tap the compare button.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.slate)),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Vendors'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(compareVendorsProvider.notifier).clear();
              context.pop();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vendor header cards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 110),
                ...vendors.map((v) => Expanded(child: _VendorHeader(vendor: v))),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            // Comparison rows
            ..._buildRows(context, vendors),
            const SizedBox(height: 24),
            // Book buttons
            Row(
              children: [
                const SizedBox(width: 110),
                ...vendors.map(
                  (v) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilledButton(
                        onPressed: () =>
                            context.push('/booking/new', extra: v),
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(60, 44)),
                        child: const Text('Book', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRows(BuildContext ctx, List<Vendor> vendors) {
    final rows = <_CompareRow>[
      _CompareRow(
        'Rating',
        vendors.map((v) => '⭐ ${v.ratingAvg.toStringAsFixed(1)}').toList(),
        highlight: true,
      ),
      _CompareRow(
        'Category',
        vendors.map((v) => v.category).toList(),
      ),
      _CompareRow(
        'City',
        vendors.map((v) => v.city ?? '—').toList(),
      ),
      _CompareRow(
        'Base Price',
        vendors
            .map((v) =>
                v.basePrice != null ? Fmt.currency(v.basePrice!) : '—')
            .toList(),
        highlight: true,
      ),
      _CompareRow(
        'Verified',
        vendors
            .map((v) => v.isVerified ? '✅ Yes' : '❌ No')
            .toList(),
      ),
      _CompareRow(
        'Portfolio',
        vendors
            .map((v) => '${v.portfolioUrls.length} photos')
            .toList(),
      ),
    ];
    return rows.map((r) => _CompareRowWidget(row: r, count: vendors.length)).toList();
  }
}

class _CompareRow {
  final String label;
  final List<String> values;
  final bool highlight;
  const _CompareRow(this.label, this.values, {this.highlight = false});
}

class _CompareRowWidget extends StatelessWidget {
  const _CompareRowWidget({required this.row, required this.count});
  final _CompareRow row;
  final int count;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: row.highlight ? AppColors.ivory : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(
              row.label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.slate),
            ),
          ),
          ...List.generate(
            count,
            (i) => Expanded(
              child: Text(
                i < row.values.length ? row.values[i] : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: row.highlight ? FontWeight.w700 : FontWeight.w400,
                  color: row.highlight ? AppColors.deepMaroon : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorHeader extends StatelessWidget {
  const _VendorHeader({required this.vendor});
  final Vendor vendor;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 70,
              height: 70,
              child: vendor.avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: vendor.avatarUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AppColors.ivory,
                      child: const Icon(Icons.storefront,
                          size: 32, color: AppColors.deepMaroon),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            vendor.name ?? 'Vendor',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (vendor.isVerified)
            const Icon(Icons.verified, color: Colors.blue, size: 14),
        ],
      ),
    );
  }
}

// Floating compare bar shown when vendors are selected in Explore
class CompareBar extends ConsumerWidget {
  const CompareBar({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(compareVendorsProvider);
    if (vendors.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.deepMaroon,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Expanded(
              child: Text(
                '${vendors.length} vendor${vendors.length > 1 ? 's' : ''} selected',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            if (vendors.length >= 2)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.saffron,
                    minimumSize: const Size(80, 36)),
                onPressed: () => context.push('/compare'),
                child: const Text('Compare'),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () =>
                  ref.read(compareVendorsProvider.notifier).clear(),
              icon: const Icon(Icons.close, color: Colors.white70),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
      ),
    );
  }
}
