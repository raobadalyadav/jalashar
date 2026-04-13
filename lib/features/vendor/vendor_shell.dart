import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/permissions.dart';

class VendorShell extends ConsumerStatefulWidget {
  const VendorShell({super.key});
  @override
  ConsumerState<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends ConsumerState<VendorShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider).signOut(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          _VendorOverview(),
          _VendorBookings(),
          _VendorProfile(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.store), label: 'Profile'),
        ],
      ),
    );
  }
}

class _VendorOverview extends ConsumerWidget {
  const _VendorOverview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(vendorBookingsProvider);
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final pending = list.where((b) => b.status == BookingStatus.pending).length;
        final confirmed = list.where((b) => b.status == BookingStatus.confirmed).length;
        final totalEarnings = list
            .where((b) => b.status == BookingStatus.completed)
            .fold<double>(0, (s, b) => s + b.totalAmount);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Expanded(child: _StatCard('Pending', '$pending', Icons.hourglass_top)),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatCard('Confirmed', '$confirmed', Icons.check_circle_outline)),
            ]),
            const SizedBox(height: 12),
            _StatCard('Total Earnings', Fmt.currency(totalEarnings), Icons.account_balance_wallet),
            const SizedBox(height: 20),
            Text('Recent Bookings',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...list.take(5).map((b) => Card(
                  child: ListTile(
                    title: Text(Fmt.date(b.eventDate)),
                    subtitle: Text(b.venue ?? ''),
                    trailing: Text(b.status.label),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.icon);
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.saffron),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.deepMaroon)),
          ],
        ),
      ),
    );
  }
}

class _VendorBookings extends ConsumerWidget {
  const _VendorBookings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(vendorBookingsProvider);
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event: ${Fmt.date(b.eventDate)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (b.venue != null) Text('📍 ${b.venue}'),
                  Text('Total: ${Fmt.currency(b.totalAmount)}'),
                  const SizedBox(height: 8),
                  if (b.status == BookingStatus.pending)
                    Row(children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            await ref
                                .read(bookingRepoProvider)
                                .updateStatus(b.id, BookingStatus.confirmed);
                            ref.invalidate(vendorBookingsProvider);
                          },
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await ref
                                .read(bookingRepoProvider)
                                .updateStatus(b.id, BookingStatus.cancelled);
                            ref.invalidate(vendorBookingsProvider);
                          },
                          child: const Text('Decline'),
                        ),
                      ),
                    ])
                  else
                    Chip(label: Text(b.status.label)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VendorProfile extends ConsumerStatefulWidget {
  const _VendorProfile();
  @override
  ConsumerState<_VendorProfile> createState() => _VendorProfileState();
}

class _VendorProfileState extends ConsumerState<_VendorProfile> {
  final _category = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _price = TextEditingController();
  final List<String> _portfolio = [];
  bool _loading = false;

  Future<void> _addPhoto() async {
    if (!await AppPermissions.photos()) return;
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return;
    setState(() => _loading = true);
    try {
      final url = await ref
          .read(storageRepoProvider)
          .uploadPortfolio(File(picked.path));
      setState(() => _portfolio.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(vendorRepoProvider).upsertMyVendor(
            category: _category.text,
            bio: _bio.text,
            city: _city.text,
            basePrice: double.tryParse(_price.text) ?? 0,
            portfolioUrls: _portfolio,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
            controller: _category,
            decoration: const InputDecoration(
                labelText: 'Category (photographer, dj, caterer...)')),
        const SizedBox(height: 12),
        TextField(
            controller: _bio,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'About your business')),
        const SizedBox(height: 12),
        TextField(
            controller: _city, decoration: const InputDecoration(labelText: 'City')),
        const SizedBox(height: 12),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Base Price (₹)'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Text('Portfolio (${_portfolio.length})',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton.icon(
              onPressed: _loading ? null : _addPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_portfolio.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _portfolio.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: _portfolio[i],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton.filled(
                      iconSize: 14,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                        padding: const EdgeInsets.all(4),
                      ),
                      icon: const Icon(Icons.close, size: 14),
                      onPressed: () => setState(() => _portfolio.removeAt(i)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _save,
          child: Text(_loading ? '...' : 'Save Profile'),
        ),
      ],
    );
  }
}
