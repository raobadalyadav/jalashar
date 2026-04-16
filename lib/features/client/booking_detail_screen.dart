import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

final _bookingDetailProvider =
    FutureProvider.family<Booking, String>((ref, id) =>
        ref.watch(bookingRepoProvider).getById(id));

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() =>
      _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime eventDate) {
    final diff = eventDate.difference(DateTime.now());
    if (diff.isNegative || diff.inDays > 30) return;
    setState(() => _remaining = diff);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = eventDate.difference(DateTime.now());
      if (!mounted || r.isNegative) {
        _timer?.cancel();
        return;
      }
      setState(() => _remaining = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_bookingDetailProvider(widget.bookingId));
    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (b) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _startCountdown(b.eventDate));
        return _BookingDetailView(b: b, remaining: _remaining);
      },
    );
  }
}

class _BookingDetailView extends ConsumerWidget {
  const _BookingDetailView({required this.b, required this.remaining});
  final Booking b;
  final Duration remaining;

  Color get _statusColor => switch (b.status) {
        BookingStatus.confirmed => AppColors.success,
        BookingStatus.inProgress => AppColors.warning,
        BookingStatus.completed => AppColors.info,
        BookingStatus.cancelled || BookingStatus.refunded => AppColors.danger,
        _ => AppColors.slate,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUpcoming = b.eventDate.isAfter(DateTime.now()) &&
        (b.status == BookingStatus.pending ||
            b.status == BookingStatus.confirmed);
    final canModify = b.status == BookingStatus.pending ||
        b.status == BookingStatus.confirmed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(_bookingDetailProvider(b.id)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status header ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: _statusColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_statusIcon, color: _statusColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      b.status.label,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                if (remaining.inSeconds > 0 && isUpcoming) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        AppColors.violetDeep,
                        AppColors.violet
                      ]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          remaining.inDays > 0
                              ? '${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m'
                              : '${remaining.inHours}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Status timeline ──────────────────────────────────────────
          _StatusTimeline(status: b.status),

          const SizedBox(height: 16),

          // ── Booking info ─────────────────────────────────────────────
          _InfoCard(
            title: 'Event Details',
            icon: Icons.event_rounded,
            children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Event Date',
                value: Fmt.date(b.eventDate),
              ),
              if (b.venue != null)
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Venue',
                  value: b.venue!,
                ),
              if (b.guestCount != null)
                _InfoRow(
                  icon: Icons.group_outlined,
                  label: 'Guests',
                  value: '${b.guestCount} guests',
                ),
              if (b.notes != null)
                _InfoRow(
                  icon: Icons.notes_rounded,
                  label: 'Notes',
                  value: b.notes!,
                ),
              _InfoRow(
                icon: Icons.access_time_rounded,
                label: 'Booked On',
                value: Fmt.dateTime(b.createdAt),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Financial breakdown ─────────────────────────────────────
          _InfoCard(
            title: 'Payment',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              _InfoRow(
                icon: Icons.receipt_long_outlined,
                label: 'Total Amount',
                value: Fmt.currency(b.totalAmount),
                valueColor: AppColors.charcoal,
                bold: true,
              ),
              _InfoRow(
                icon: Icons.check_circle_outline_rounded,
                label: 'Advance Paid',
                value: Fmt.currency(b.advancePaid),
                valueColor: AppColors.success,
              ),
              _InfoRow(
                icon: Icons.pending_outlined,
                label: 'Balance Due',
                value: Fmt.currency(b.totalAmount - b.advancePaid),
                valueColor: b.totalAmount - b.advancePaid > 0
                    ? AppColors.danger
                    : AppColors.success,
                bold: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Booking ID ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1B3A)
                  : AppColors.violetSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.tag, size: 14, color: AppColors.slate),
                const SizedBox(width: 8),
                Text('Booking ID: ',
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 12)),
                Expanded(
                  child: Text(
                    b.id.substring(0, 8).toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Actions ─────────────────────────────────────────────────
          Text('Actions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (b.vendorId != null)
                _ActionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: () => context
                      .push('/chat/${b.id}/${b.vendorId}'),
                ),
              _ActionBtn(
                icon: Icons.checklist_rounded,
                label: 'Checklist',
                onTap: () => context.push('/checklist/${b.id}'),
              ),
              if (b.status == BookingStatus.confirmed && isUpcoming)
                _ActionBtn(
                  icon: Icons.group_add_outlined,
                  label: 'Invite Guests',
                  onTap: () =>
                      context.push('/guest-invite/${b.id}'),
                ),
              if (b.status == BookingStatus.completed &&
                  b.vendorId != null)
                _ActionBtn(
                  icon: Icons.star_outline_rounded,
                  label: 'Rate Vendor',
                  color: AppColors.gold,
                  filled: true,
                  onTap: () => context
                      .push('/review/${b.id}/${b.vendorId}'),
                ),
              if (canModify && isUpcoming)
                _ActionBtn(
                  icon: Icons.edit_calendar_rounded,
                  label: 'Reschedule',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now()
                          .add(const Duration(days: 1)),
                      lastDate: DateTime.now()
                          .add(const Duration(days: 730)),
                      initialDate: b.eventDate,
                    );
                    if (picked == null) return;
                    try {
                      await ref
                          .read(bookingRepoProvider)
                          .reschedule(b.id, picked);
                      ref.invalidate(
                          _bookingDetailProvider(b.id));
                      ref.invalidate(myBookingsProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Booking rescheduled')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')));
                      }
                    }
                  },
                ),
              if (canModify)
                _ActionBtn(
                  icon: Icons.cancel_outlined,
                  label: 'Cancel',
                  color: AppColors.danger,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Cancel Booking?'),
                        content: const Text(
                            'This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Keep'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.danger),
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text('Cancel Booking'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    await ref
                        .read(bookingRepoProvider)
                        .cancel(b.id);
                    ref.invalidate(_bookingDetailProvider(b.id));
                    ref.invalidate(myBookingsProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Booking cancelled')));
                    }
                  },
                ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  IconData get _statusIcon => switch (b.status) {
        BookingStatus.confirmed => Icons.check_circle_rounded,
        BookingStatus.inProgress => Icons.play_circle_rounded,
        BookingStatus.completed => Icons.done_all_rounded,
        BookingStatus.cancelled => Icons.cancel_rounded,
        BookingStatus.refunded => Icons.replay_rounded,
        _ => Icons.hourglass_top_rounded,
      };
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status});
  final BookingStatus status;

  static const _steps = [
    (BookingStatus.pending, 'Booked', Icons.bookmark_added_outlined),
    (BookingStatus.confirmed, 'Confirmed', Icons.check_circle_outlined),
    (BookingStatus.inProgress, 'In Progress', Icons.play_circle_outlined),
    (BookingStatus.completed, 'Completed', Icons.done_all_rounded),
  ];

  int get _currentIdx => switch (status) {
        BookingStatus.pending => 0,
        BookingStatus.confirmed => 1,
        BookingStatus.inProgress => 2,
        BookingStatus.completed => 3,
        _ => -1,
      };

  @override
  Widget build(BuildContext context) {
    if (status == BookingStatus.cancelled ||
        status == BookingStatus.refunded) {
      return const SizedBox.shrink();
    }
    final idx = _currentIdx;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.violetMid.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: _steps.asMap().entries.map((entry) {
          final i = entry.key;
          final (_, label, icon) = entry.value;
          final done = i <= idx;
          final active = i == idx;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i != 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: done
                              ? AppColors.violet
                              : AppColors.violetMid,
                        ),
                      ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done
                            ? AppColors.violet
                            : AppColors.violetMid,
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: AppColors.violet
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        icon,
                        color: done ? Colors.white : AppColors.slate,
                        size: 16,
                      ),
                    ),
                    if (i != _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < idx
                              ? AppColors.violet
                              : AppColors.violetMid,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: active
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: active
                        ? AppColors.violet
                        : AppColors.slate,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.title,
      required this.icon,
      required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.violetMid.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.violet, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.violet),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.slate),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  color: AppColors.slate, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight:
                    bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.filled = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.violet,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600)),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color ?? AppColors.violet,
        side: BorderSide(
            color: (color ?? AppColors.violet)
                .withValues(alpha: 0.5)),
        minimumSize: Size.zero,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
