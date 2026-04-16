import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

class PayoutsScreen extends ConsumerWidget {
  const PayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payouts = ref.watch(myPayoutsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Payouts')),
      body: payouts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          final pending = list
              .where((p) => p.status != 'paid')
              .fold<double>(0, (s, p) => s + p.amount);
          final paid = list
              .where((p) => p.status == 'paid')
              .fold<double>(0, (s, p) => s + p.amount);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Expanded(child: _StatCard('Paid', Fmt.currency(paid), AppColors.success)),
                const SizedBox(width: 12),
                Expanded(child: _StatCard('Pending', Fmt.currency(pending), AppColors.saffron)),
              ]),
              const SizedBox(height: 20),
              const SectionHeader(title: 'History'),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.account_balance_wallet,
                  title: 'No payouts yet',
                  subtitle: 'Completed bookings will appear here',
                ),
              ...list.map((p) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            (p.status == 'paid' ? AppColors.success : AppColors.saffron)
                                .withOpacity(0.15),
                        child: Icon(
                          p.status == 'paid' ? Icons.check : Icons.hourglass_top,
                          color: p.status == 'paid'
                              ? AppColors.success
                              : AppColors.saffron,
                        ),
                      ),
                      title: Text(Fmt.currency(p.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${p.method ?? "—"} · ${Fmt.date(p.createdAt)}'),
                      trailing: StatusBadge(
                        label: p.status,
                        color: p.status == 'paid'
                            ? AppColors.success
                            : AppColors.saffron,
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.title, this.value, this.color);
  final String title, value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
