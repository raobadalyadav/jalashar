import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BookingConfirmationScreen extends ConsumerStatefulWidget {
  const BookingConfirmationScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends ConsumerState<BookingConfirmationScreen> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(DateTime eventDate) {
    final now = DateTime.now();
    final diff = eventDate.difference(now);
    if (diff.isNegative) return;
    setState(() => _remaining = diff);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = eventDate.difference(DateTime.now());
      if (r.isNegative) {
        _timer?.cancel();
        return;
      }
      if (mounted) setState(() => _remaining = r);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(
        FutureProvider.autoDispose((ref) =>
            ref.watch(bookingRepoProvider).getById(widget.bookingId)).future);

    return FutureBuilder<Booking>(
      future: bookingAsync,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final booking = snap.data!;
        if (_timer == null && booking.eventDate.isAfter(DateTime.now())) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _startCountdown(booking.eventDate));
        }
        return _ConfirmationBody(
          booking: booking,
          remaining: _remaining,
        );
      },
    );
  }
}

class _ConfirmationBody extends StatelessWidget {
  const _ConfirmationBody({required this.booking, required this.remaining});
  final Booking booking;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Animated success circle
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success, width: 3),
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: AppColors.success),
              )
                  .animate()
                  .scale(begin: const Offset(0.3, 0.3), duration: 400.ms,
                      curve: Curves.elasticOut)
                  .fadeIn(),

              const SizedBox(height: 20),
              Text(
                'Booking Confirmed!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800, color: AppColors.deepMaroon),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

              const SizedBox(height: 6),
              Text(
                'Your event is all set. Check the details below.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // Booking ID card
              _DetailCard(
                children: [
                  _Row(
                    'Booking ID',
                    booking.id.substring(0, 8).toUpperCase(),
                    icon: Icons.confirmation_number_outlined,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: booking.id));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Booking ID copied')));
                    },
                    trailing: const Icon(Icons.copy, size: 16),
                  ),
                  const Divider(height: 1),
                  _Row('Event Date', Fmt.date(booking.eventDate),
                      icon: Icons.calendar_today_outlined),
                  if (booking.venue != null) ...[
                    const Divider(height: 1),
                    _Row('Venue', booking.venue!, icon: Icons.location_on_outlined),
                  ],
                  if (booking.guestCount != null) ...[
                    const Divider(height: 1),
                    _Row('Guests', '${booking.guestCount}',
                        icon: Icons.group_outlined),
                  ],
                  const Divider(height: 1),
                  _Row('Status', booking.status.label,
                      icon: Icons.info_outline,
                      valueColor: AppColors.saffron),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),

              // Payment card
              _DetailCard(
                children: [
                  _Row('Total Amount', Fmt.currency(booking.totalAmount),
                      icon: Icons.currency_rupee,
                      valueColor: AppColors.deepMaroon,
                      bold: true),
                  const Divider(height: 1),
                  _Row(
                    'Advance (30%)',
                    Fmt.currency(booking.totalAmount * 0.3),
                    icon: Icons.payment,
                    valueColor: AppColors.success,
                  ),
                  const Divider(height: 1),
                  _Row(
                    'Balance Due',
                    Fmt.currency(booking.totalAmount * 0.7),
                    icon: Icons.pending_actions,
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

              // Countdown
              if (remaining.inSeconds > 0) ...[
                const SizedBox(height: 16),
                _CountdownCard(remaining: remaining)
                    .animate()
                    .fadeIn(delay: 600.ms),
              ],

              const SizedBox(height: 28),

              // Action buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        context.push('/checklist/${booking.id}'),
                    icon: const Icon(Icons.checklist),
                    label: const Text('Checklist'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.home),
                    label: const Text('Go Home'),
                  ),
                ),
              ]).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: () => context.push('/booking/new'),
                icon: const Icon(Icons.add),
                label: const Text('Book Another Service'),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(
    this.label,
    this.value, {
    required this.icon,
    this.onTap,
    this.trailing,
    this.valueColor,
    this.bold = false,
  });
  final String label, value;
  final IconData icon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      onTap: onTap,
      leading: Icon(icon, size: 20, color: AppColors.slate),
      title: Text(label,
          style: Theme.of(context).textTheme.bodySmall),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
              fontSize: bold ? 16 : null,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.remaining});
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final mins = remaining.inMinutes % 60;
    final secs = remaining.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.saffron, AppColors.deepMaroon],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            '⏰ Countdown to Your Event',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CountUnit(days, 'Days'),
              _Separator(),
              _CountUnit(hours, 'Hours'),
              _Separator(),
              _CountUnit(mins, 'Mins'),
              _Separator(),
              _CountUnit(secs, 'Secs'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountUnit extends StatelessWidget {
  const _CountUnit(this.value, this.label);
  final int value;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Text(':',
        style: TextStyle(
            color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w700));
  }
}
