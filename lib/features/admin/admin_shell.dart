import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

final _pendingVendorsProvider =
    FutureProvider((ref) => ref.watch(vendorRepoProvider).listPendingVerification());
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

// ── Overview ─────────────────────────────────────────────────────────────────

class _AdminOverview extends ConsumerWidget {
  const _AdminOverview();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(_allBookingsProvider);
    final pending = ref.watch(_pendingVendorsProvider);

    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final revenue = list
            .where((b) => b.status == BookingStatus.completed)
            .fold<double>(0, (s, b) => s + b.totalAmount);
        final platformFee = revenue * 0.1;
        final statusCounts = <BookingStatus, int>{};
        for (final b in list) {
          statusCounts[b.status] = (statusCounts[b.status] ?? 0) + 1;
        }

        // Monthly revenue (last 6 months)
        final monthly = <String, double>{};
        for (final b in list.where((x) => x.status == BookingStatus.completed)) {
          final key = '${b.createdAt.year}-${b.createdAt.month.toString().padLeft(2, '0')}';
          monthly[key] = (monthly[key] ?? 0) + b.totalAmount;
        }
        final sortedMonths = monthly.keys.toList()..sort();
        final recentMonths = sortedMonths.length > 6
            ? sortedMonths.sublist(sortedMonths.length - 6)
            : sortedMonths;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_allBookingsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _StatCard('Total Bookings', '${list.length}',
                      Icons.event, AppColors.saffron),
                  _StatCard('Gross Revenue', Fmt.currency(revenue),
                      Icons.trending_up, AppColors.success),
                  _StatCard('Platform Fee', Fmt.currency(platformFee),
                      Icons.account_balance, Colors.blue),
                  _StatCard(
                      'Pending Verify',
                      '${pending.valueOrNull?.length ?? 0}',
                      Icons.pending_actions,
                      AppColors.danger),
                ],
              ),

              const SizedBox(height: 20),

              // Status breakdown
              Text('Booking Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...BookingStatus.values.map((s) {
                final count = statusCounts[s] ?? 0;
                final pct = list.isEmpty ? 0.0 : count / list.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.label,
                              style: const TextStyle(fontSize: 13)),
                          Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 8,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                              _statusColor(s)),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Monthly revenue chart (simple bar)
              if (recentMonths.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Monthly Revenue (completed)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: recentMonths.map((m) {
                      final val = monthly[m] ?? 0;
                      final maxVal = monthly.values.isEmpty
                          ? 1.0
                          : monthly.values.reduce((a, b) => a > b ? a : b);
                      final ratio = maxVal == 0 ? 0.0 : val / maxVal;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                val > 0
                                    ? '₹${(val / 1000).toStringAsFixed(0)}K'
                                    : '',
                                style: const TextStyle(fontSize: 9),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: ratio.clamp(0.05, 1.0),
                                  widthFactor: 0.7,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.saffron,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m.substring(5), // MM
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(BookingStatus s) => switch (s) {
        BookingStatus.confirmed => AppColors.success,
        BookingStatus.inProgress => AppColors.saffron,
        BookingStatus.completed => Colors.blue,
        BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
        _ => AppColors.slate,
      };
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.icon, this.color);
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context).textTheme.bodySmall),
                Text(value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending Vendor Verification ───────────────────────────────────────────────

class _PendingVendors extends ConsumerWidget {
  const _PendingVendors();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(_pendingVendorsProvider);
    return pending.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppColors.success),
                SizedBox(height: 12),
                Text('All vendors verified!',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(_pendingVendorsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        CircleAvatar(
                          backgroundColor: AppColors.ivory,
                          child: Text(
                            (v.name ?? 'V').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepMaroon),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name ?? 'Vendor',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              Text('${v.category} · ${v.city ?? ""}',
                                  style: const TextStyle(
                                      color: AppColors.slate,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ]),
                      if (v.bio != null) ...[
                        const SizedBox(height: 8),
                        Text(v.bio!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13)),
                      ],
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(vendorRepoProvider)
                                  .verify(v.id, true);
                              ref.invalidate(_pendingVendorsProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Vendor verified ✓')));
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Approve'),
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.success,
                                minimumSize: const Size(60, 38)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref
                                  .read(vendorRepoProvider)
                                  .verify(v.id, false);
                              ref.invalidate(_pendingVendorsProvider);
                            },
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(
                                    color: AppColors.danger),
                                minimumSize: const Size(60, 38)),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── All Bookings ──────────────────────────────────────────────────────────────

class _AllBookings extends ConsumerWidget {
  const _AllBookings();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(_allBookingsProvider);
    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(_allBookingsProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final b = list[i];
            final statusColor = switch (b.status) {
              BookingStatus.confirmed => AppColors.success,
              BookingStatus.inProgress => AppColors.saffron,
              BookingStatus.completed => Colors.blue,
              BookingStatus.cancelled ||
              BookingStatus.refunded =>
                AppColors.danger,
              _ => AppColors.slate,
            };
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                title: Text(
                  '${Fmt.date(b.eventDate)} · ${Fmt.currency(b.totalAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${b.venue ?? "No venue"} · ${b.status.label}',
                  style: TextStyle(color: statusColor),
                ),
                trailing: Text(
                  b.id.substring(0, 6).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.slate),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
