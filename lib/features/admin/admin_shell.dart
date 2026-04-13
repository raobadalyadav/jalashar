import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

final _pendingVendorsProvider = FutureProvider(
    (ref) => ref.watch(vendorRepoProvider).listPendingVerification());
final _allBookingsProvider =
    FutureProvider((ref) => ref.watch(bookingRepoProvider).listAll());

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console'),
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
          _AdminOverview(),
          _PendingVendors(),
          _AllBookings(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.verified_user), label: 'Verify'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Bookings'),
        ],
      ),
    );
  }
}

class _AdminOverview extends ConsumerWidget {
  const _AdminOverview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(_allBookingsProvider);
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final revenue = list.fold<double>(0, (s, b) => s + b.totalAmount);
        final platformFee = revenue * 0.1;
        return GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _Stat('Total Bookings', '${list.length}', Icons.event),
            _Stat('Gross Revenue', Fmt.currency(revenue), Icons.trending_up),
            _Stat('Platform Fee (10%)', Fmt.currency(platformFee), Icons.account_balance),
            _Stat('Active', '${list.where((b) => b.status != BookingStatus.cancelled).length}',
                Icons.check_circle),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.title, this.value, this.icon);
  final String title, value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.saffron, size: 32),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            Text(value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700, color: AppColors.deepMaroon)),
          ],
        ),
      ),
    );
  }
}

class _PendingVendors extends ConsumerWidget {
  const _PendingVendors();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(_pendingVendorsProvider);
    return pending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final v = list[i];
          return Card(
            child: ListTile(
              title: Text(v.name ?? 'Vendor'),
              subtitle: Text('${v.category} · ${v.city ?? ""}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: AppColors.success),
                    onPressed: () async {
                      await ref.read(vendorRepoProvider).verify(v.id, true);
                      ref.invalidate(_pendingVendorsProvider);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: AppColors.danger),
                    onPressed: () async {
                      await ref.read(vendorRepoProvider).verify(v.id, false);
                      ref.invalidate(_pendingVendorsProvider);
                    },
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

class _AllBookings extends ConsumerWidget {
  const _AllBookings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(_allBookingsProvider);
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final b = list[i];
          return Card(
            child: ListTile(
              title: Text('${Fmt.date(b.eventDate)} · ${Fmt.currency(b.totalAmount)}'),
              subtitle: Text('${b.venue ?? ""} · ${b.status.label}'),
            ),
          );
        },
      ),
    );
  }
}
