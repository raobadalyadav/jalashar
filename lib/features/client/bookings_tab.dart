import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BookingsTab extends ConsumerWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No bookings yet'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _BookingCard(b: list[i]),
                ),
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.b});
  final Booking b;

  Color _statusColor() => switch (b.status) {
        BookingStatus.confirmed => AppColors.success,
        BookingStatus.inProgress => AppColors.saffron,
        BookingStatus.completed => Colors.blue,
        BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
        _ => AppColors.slate,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Fmt.date(b.eventDate),
                    style: Theme.of(context).textTheme.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(b.status.label,
                      style: TextStyle(
                          color: _statusColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (b.venue != null) Text('📍 ${b.venue}'),
            if (b.guestCount != null) Text('👥 ${b.guestCount} guests'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${Fmt.currency(b.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (b.advancePaid > 0)
                  Text('Paid: ${Fmt.currency(b.advancePaid)}',
                      style: const TextStyle(color: AppColors.success)),
              ],
            ),
            if (b.status == BookingStatus.completed && b.vendorId != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (ctx) => OutlinedButton.icon(
                    onPressed: () =>
                        ctx.push('/review/${b.id}/${b.vendorId}'),
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Rate Vendor'),
                  )),
            ],
            const SizedBox(height: 8),
            Builder(
              builder: (ctx) => Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ctx.push('/checklist/${b.id}'),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Checklist'),
                  ),
                  if (b.vendorId != null)
                    TextButton.icon(
                      onPressed: () => ctx.push('/chat/${b.id}/${b.vendorId}'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Message'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
