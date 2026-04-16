import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key, required this.vendorId});
  final String vendorId;

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  Set<DateTime> _blocked = {};
  DateTime _focused = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _blocked = await ref
          .read(availabilityRepoProvider)
          .blockedDates(widget.vendorId);
    } catch (e) {
      if (mounted) AppSnack.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    try {
      await ref.read(availabilityRepoProvider).toggleBlock(widget.vendorId, d);
      setState(() {
        if (_blocked.contains(d)) {
          _blocked.remove(d);
        } else {
          _blocked.add(d);
        }
      });
    } catch (e) {
      if (mounted) AppSnack.error(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Availability')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: AppColors.ivory,
                  child: Row(children: const [
                    Icon(Icons.info_outline, color: AppColors.deepMaroon),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tap any date to block/unblock. Blocked dates hide you from client searches for that day.',
                        style: TextStyle(color: AppColors.deepMaroon),
                      ),
                    ),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _MiniCalendar(
                    month: _focused,
                    blocked: _blocked,
                    onPrev: () => setState(() =>
                        _focused = DateTime(_focused.year, _focused.month - 1)),
                    onNext: () => setState(() =>
                        _focused = DateTime(_focused.year, _focused.month + 1)),
                    onTap: _toggle,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _legend('Available', AppColors.success),
                      _legend('Blocked', AppColors.danger),
                      _legend('Today', AppColors.saffron),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legend(String label, Color c) => Row(children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ]);
}

class _MiniCalendar extends StatelessWidget {
  const _MiniCalendar({
    required this.month,
    required this.blocked,
    required this.onPrev,
    required this.onNext,
    required this.onTap,
  });
  final DateTime month;
  final Set<DateTime> blocked;
  final VoidCallback onPrev, onNext;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startOffset = first.weekday % 7; // Sunday-start
    final today = DateTime.now();
    final isToday =
        (DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;

    return Column(
      children: [
        Row(children: [
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
          Expanded(
            child: Text(
              '${_monthName(month.month)} ${month.year}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
        ]),
        Row(
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, childAspectRatio: 1),
          itemCount: daysInMonth + startOffset,
          itemBuilder: (_, i) {
            if (i < startOffset) return const SizedBox.shrink();
            final day = i - startOffset + 1;
            final date = DateTime(month.year, month.month, day);
            final isBlocked = blocked.contains(date);
            final past = date.isBefore(DateTime(today.year, today.month, today.day));
            return GestureDetector(
              onTap: past ? null : () => onTap(date),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBlocked
                      ? AppColors.danger
                      : isToday(date)
                          ? AppColors.saffron
                          : past
                              ? Colors.grey.shade200
                              : AppColors.ivory,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: (isBlocked || isToday(date))
                        ? Colors.white
                        : past
                            ? AppColors.slate
                            : AppColors.deepMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthName(int m) => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ][m - 1];
}
