import 'dart:async';

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
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myBookingsProvider),
          ),
        ],
      ),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: AppColors.ivory, shape: BoxShape.circle),
                    child: const Icon(Icons.event_note,
                        size: 48, color: AppColors.deepMaroon),
                  ),
                  const SizedBox(height: 16),
                  const Text('No bookings yet',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Your upcoming events will appear here',
                      style: TextStyle(color: AppColors.slate)),
                ],
              ),
            );
          }

          // Separate upcoming vs past
          final now = DateTime.now();
          final upcoming = list
              .where((b) =>
                  b.eventDate.isAfter(now) &&
                  b.status != BookingStatus.cancelled &&
                  b.status != BookingStatus.refunded)
              .toList();
          final past = list
              .where((b) =>
                  b.eventDate.isBefore(now) ||
                  b.status == BookingStatus.cancelled ||
                  b.status == BookingStatus.refunded)
              .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myBookingsProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (upcoming.isNotEmpty) ...[
                  const _SectionLabel('Upcoming'),
                  ...upcoming.map((b) => _BookingCard(b: b)),
                ],
                if (past.isNotEmpty) ...[
                  const _SectionLabel('Past & Cancelled'),
                  ...past.map((b) => _BookingCard(b: b)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.slate,
        ),
      ),
    );
  }
}

class _BookingCard extends ConsumerStatefulWidget {
  const _BookingCard({required this.b});
  final Booking b;

  @override
  ConsumerState<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends ConsumerState<_BookingCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    final diff = widget.b.eventDate.difference(DateTime.now());
    if (diff.isNegative || diff.inDays > 30) return;
    setState(() => _remaining = diff);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = widget.b.eventDate.difference(DateTime.now());
      if (!mounted || r.isNegative) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining = r);
    });
  }

  Color _statusColor() => switch (widget.b.status) {
        BookingStatus.confirmed => AppColors.success,
        BookingStatus.inProgress => AppColors.saffron,
        BookingStatus.completed => Colors.blue,
        BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
        _ => AppColors.slate,
      };

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text(
            'This action cannot be undone. Refund per cancellation policy.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(bookingRepoProvider).cancel(widget.b.id);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _reschedule() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: widget.b.eventDate,
      helpText: 'Pick new event date',
    );
    if (picked == null) return;
    try {
      await ref.read(bookingRepoProvider).reschedule(widget.b.id, picked);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking rescheduled')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.b;
    final canModify = b.status == BookingStatus.pending ||
        b.status == BookingStatus.confirmed;
    final isUpcoming =
        b.eventDate.isAfter(DateTime.now()) && canModify;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Fmt.date(b.eventDate),
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.12),
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

            if (b.venue != null)
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.slate),
                const SizedBox(width: 4),
                Expanded(
                    child: Text(b.venue!,
                        style: const TextStyle(color: AppColors.slate))),
              ]),

            if (b.guestCount != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.group_outlined,
                    size: 14, color: AppColors.slate),
                const SizedBox(width: 4),
                Text('${b.guestCount} guests',
                    style: const TextStyle(color: AppColors.slate)),
              ]),
            ],

            const SizedBox(height: 10),

            // Countdown chip (show if event is within 30 days)
            if (isUpcoming && _remaining.inSeconds > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.saffron, AppColors.deepMaroon]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    _remaining.inDays > 0
                        ? '${_remaining.inDays}d ${_remaining.inHours % 24}h ${_remaining.inMinutes % 60}m'
                        : '${_remaining.inHours}h ${_remaining.inMinutes % 60}m ${_remaining.inSeconds % 60}s',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),

            const SizedBox(height: 10),

            // Financial row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: ${Fmt.currency(b.totalAmount)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (b.advancePaid > 0)
                  Text('Paid: ${Fmt.currency(b.advancePaid)}',
                      style:
                          const TextStyle(color: AppColors.success, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 10),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Checklist
                OutlinedButton.icon(
                  onPressed: () => context.push('/checklist/${b.id}'),
                  icon: const Icon(Icons.checklist, size: 16),
                  label: const Text('Checklist'),
                  style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                ),

                // Chat
                if (b.vendorId != null)
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/chat/${b.id}/${b.vendorId}'),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),

                // Rate vendor
                if (b.status == BookingStatus.completed && b.vendorId != null)
                  FilledButton.icon(
                    onPressed: () =>
                        context.push('/review/${b.id}/${b.vendorId}'),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Rate'),
                    style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),

                // Reschedule
                if (canModify && isUpcoming)
                  TextButton.icon(
                    onPressed: _reschedule,
                    icon: const Icon(Icons.edit_calendar, size: 16),
                    label: const Text('Reschedule'),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),

                // Cancel
                if (canModify)
                  TextButton.icon(
                    onPressed: _cancel,
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Cancel'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        visualDensity: VisualDensity.compact),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
