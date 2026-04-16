import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
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
          _UsersTab(),
          _ReportsTab(),
          _BroadcastTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Overview'),
          NavigationDestination(icon: Icon(Icons.verified_user), label: 'Verify'),
          NavigationDestination(icon: Icon(Icons.event), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.flag), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.campaign), label: 'Broadcast'),
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
    final stats = ref.watch(adminStatsProvider);
    final pending = ref.watch(_pendingVendorsProvider);

    return bookings.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        final statusCounts = <BookingStatus, int>{};
        for (final b in list) {
          statusCounts[b.status] = (statusCounts[b.status] ?? 0) + 1;
        }
        final monthly = <String, double>{};
        for (final b
            in list.where((x) => x.status == BookingStatus.completed)) {
          final key =
              '${b.createdAt.year}-${b.createdAt.month.toString().padLeft(2, '0')}';
          monthly[key] = (monthly[key] ?? 0) + b.totalAmount;
        }
        final sortedMonths = monthly.keys.toList()..sort();
        final recentMonths = sortedMonths.length > 6
            ? sortedMonths.sublist(sortedMonths.length - 6)
            : sortedMonths;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_allBookingsProvider);
            ref.invalidate(adminStatsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Platform stats from adminStatsProvider
              stats.when(
                loading: () => const SizedBox.shrink(),
                error: (e, _) => const SizedBox.shrink(),
                data: (s) => GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _StatCard('Total Users', '${s['userCount']}',
                        Icons.people, AppColors.violet),
                    _StatCard('Vendors', '${s['vendorCount']}',
                        Icons.store, AppColors.violetDeep),
                    _StatCard('Verified', '${s['verifiedVendors']}',
                        Icons.verified, AppColors.success),
                    _StatCard('Pending Verify',
                        '${pending.valueOrNull?.length ?? 0}',
                        Icons.pending_actions, AppColors.warning),
                    _StatCard('Total Bookings', '${s['totalBookings']}',
                        Icons.event, AppColors.info),
                    _StatCard('Last 7 Days', '${s['last7DaysBookings']}',
                        Icons.trending_up, AppColors.gold),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Booking status breakdown
              Text('Booking Status',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
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
                          Text(
                              '$count (${(pct * 100).toStringAsFixed(0)}%)',
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
                          valueColor:
                              AlwaysStoppedAnimation(_statusColor(s)),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Top categories
              stats.maybeWhen(
                data: (s) {
                  final cats = (s['topCategories'] as Map<String, int>)
                      .entries
                      .toList()
                    ..sort((a, b) => b.value.compareTo(a.value));
                  if (cats.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Text('Top Categories',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      ...cats.take(5).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              SizedBox(
                                  width: 120,
                                  child: Text(e.key,
                                      style: const TextStyle(fontSize: 13))),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: cats.first.value == 0
                                        ? 0
                                        : e.value / cats.first.value,
                                    minHeight: 8,
                                    backgroundColor: AppColors.violetSoft,
                                    color: AppColors.violet,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ]),
                          )),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),

              // Monthly bookings bar chart
              if (recentMonths.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Monthly Bookings (completed)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
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
                                      color: AppColors.violet,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                              top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(m.substring(5),
                                  style: const TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center),
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
        BookingStatus.inProgress => AppColors.warning,
        BookingStatus.completed => Colors.blue,
        BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
        _ => AppColors.slate,
      };
}

// ── Users Tab ─────────────────────────────────────────────────────────────────

class _UsersTab extends ConsumerWidget {
  const _UsersTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(allUsersProvider);
    return users.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(allUsersProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) => _UserTile(user: list[i]),
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  const _UserTile({required this.user});
  final PlatformUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBanned = user.isBanned;
    final isSuspended = user.isSuspended;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isBanned
              ? AppColors.danger.withValues(alpha: 0.15)
              : AppColors.violetSoft,
          child: Text(
            (user.name?.isNotEmpty == true
                    ? user.name![0]
                    : user.role?[0] ?? 'U')
                .toUpperCase(),
            style: TextStyle(
                color: isBanned ? AppColors.danger : AppColors.violet,
                fontWeight: FontWeight.w700),
          ),
        ),
        title: Row(children: [
          Expanded(
              child: Text(user.name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          if (isBanned)
            _Badge('Banned', AppColors.danger)
          else if (isSuspended)
            _Badge('Suspended', AppColors.warning),
        ]),
        subtitle: Text(
          '${user.role ?? 'user'} · ${user.city ?? 'No city'} · ${user.phone ?? 'No phone'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) => _handleAction(context, ref, action),
          itemBuilder: (_) => [
            if (!isSuspended && !isBanned)
              const PopupMenuItem(
                  value: 'suspend', child: Text('Suspend Account')),
            if (isSuspended)
              const PopupMenuItem(
                  value: 'unsuspend', child: Text('Lift Suspension')),
            if (!isBanned)
              const PopupMenuItem(
                value: 'ban',
                child: Text('Ban Permanently',
                    style: TextStyle(color: AppColors.danger)),
              ),
            if (isBanned)
              const PopupMenuItem(value: 'unban', child: Text('Unban')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(adminRepoProvider);
    try {
      switch (action) {
        case 'suspend':
          await repo.suspendUser(user.id, true);
        case 'unsuspend':
          await repo.suspendUser(user.id, false);
        case 'ban':
          final reason = await _askReason(context);
          if (reason == null) return;
          await repo.banUser(user.id, reason);
        case 'unban':
          await repo.unbanUser(user.id);
      }
      ref.invalidate(allUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('User updated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _askReason(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ban Reason'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Enter reason')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.color);
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700)),
      );
}

// ── Reports Tab ───────────────────────────────────────────────────────────────

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsProvider);
    return reports.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle, size: 64, color: AppColors.success),
              SizedBox(height: 12),
              Text('No reports!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ]),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminReportsProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final r = list[i];
              final status = r['status'] as String? ?? 'open';
              final isResolved = status == 'resolved';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(Icons.flag,
                      color: isResolved ? AppColors.success : AppColors.danger),
                  title: Text(r['reason'] as String? ?? 'Report',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r['description'] != null)
                        Text(r['description'] as String,
                            style: const TextStyle(fontSize: 12)),
                      Text('Status: $status',
                          style: TextStyle(
                              fontSize: 11,
                              color: isResolved
                                  ? AppColors.success
                                  : AppColors.danger)),
                    ],
                  ),
                  trailing: isResolved
                      ? const Icon(Icons.check_circle,
                          color: AppColors.success, size: 20)
                      : TextButton(
                          onPressed: () async {
                            await ref
                                .read(adminRepoProvider)
                                .resolveReport(r['id'] as String);
                            ref.invalidate(adminReportsProvider);
                          },
                          child: const Text('Resolve'),
                        ),
                  isThreeLine: r['description'] != null,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Broadcast Tab ─────────────────────────────────────────────────────────────

class _BroadcastTab extends ConsumerStatefulWidget {
  const _BroadcastTab();
  @override
  ConsumerState<_BroadcastTab> createState() => _BroadcastTabState();
}

class _BroadcastTabState extends ConsumerState<_BroadcastTab> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _targetRole; // null = all
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref.read(adminRepoProvider).broadcastNotification(
            title: _title.text.trim(),
            body: _body.text.trim(),
            targetRole: _targetRole,
          );
      _title.clear();
      _body.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification broadcast sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.warning, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will send a push notification to all selected users.',
                  style: TextStyle(fontSize: 13, color: AppColors.warning),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Target Audience',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Everyone'),
                selected: _targetRole == null,
                onSelected: (s) {
                  if (s) setState(() => _targetRole = null);
                },
              ),
              ChoiceChip(
                label: const Text('Clients only'),
                selected: _targetRole == 'client',
                onSelected: (s) {
                  setState(() => _targetRole = s ? 'client' : null);
                },
              ),
              ChoiceChip(
                label: const Text('Vendors only'),
                selected: _targetRole == 'vendor',
                onSelected: (s) {
                  setState(() => _targetRole = s ? 'vendor' : null);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Notification Title *',
              hintText: 'e.g. New Feature Available!',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _body,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message Body *',
              hintText: 'Write your announcement here...',
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(_sending ? 'Sending...' : 'Send Broadcast'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
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
                          backgroundColor: AppColors.violetSoft,
                          child: Text(
                            (v.name ?? 'V').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.violet),
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
                        // Featured toggle
                        IconButton(
                          tooltip: v.isFeatured ? 'Remove Featured' : 'Mark Featured',
                          icon: Icon(
                            v.isFeatured ? Icons.star : Icons.star_border,
                            color: v.isFeatured ? AppColors.gold : AppColors.slate,
                          ),
                          onPressed: () async {
                            await ref
                                .read(adminRepoProvider)
                                .setFeatured(v.id, !v.isFeatured);
                            ref.invalidate(_pendingVendorsProvider);
                          },
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
              BookingStatus.inProgress => AppColors.warning,
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
                  style: const TextStyle(fontSize: 10, color: AppColors.slate),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Stat Card ─────────────────────────────────────────────────────────────────

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
