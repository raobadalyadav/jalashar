import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(wishlistProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No saved vendors yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(wishlistProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final v = list[i];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.ivory,
                          child: Icon(Icons.storefront, color: AppColors.deepMaroon),
                        ),
                        title: Text(v.name ?? 'Vendor'),
                        subtitle: Text('${v.category} · ${v.city ?? ""}'),
                        trailing: v.basePrice != null
                            ? Text(Fmt.currency(v.basePrice!),
                                style: const TextStyle(fontWeight: FontWeight.w600))
                            : null,
                        onTap: () => context.push('/vendor-detail/${v.id}', extra: v),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
