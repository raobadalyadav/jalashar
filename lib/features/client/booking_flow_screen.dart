import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, this.vendor, this.service});
  final Vendor? vendor;
  final ServicePackage? service;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  int _step = 0;
  DateTime? _date;
  String? _eventType;
  final _guests = TextEditingController(text: '50');
  final _venue = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  static const _eventTypes = [
    'Wedding', 'Birthday', 'Corporate', 'Engagement',
    'Anniversary', 'Festival', 'Other',
  ];

  @override
  void dispose() {
    _guests.dispose();
    _venue.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Book Event'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            backgroundColor: AppColors.violetMid,
            valueColor: const AlwaysStoppedAnimation(AppColors.violet),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: 300.ms,
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: _buildStep(context),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _submitting ? null : _handleNext,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Text(
                        _step == 2 ? 'Confirm Booking' : 'Next',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    return switch (_step) {
      0 => _StepDate(
          key: const ValueKey(0),
          selected: _date,
          eventType: _eventType,
          eventTypes: _eventTypes,
          onDatePicked: (d) => setState(() => _date = d),
          onEventType: (t) => setState(() => _eventType = t),
        ),
      1 => _StepDetails(
          key: const ValueKey(1),
          guestsCtrl: _guests,
          venueCtrl: _venue,
          notesCtrl: _notes,
        ),
      _ => _StepReview(
          key: const ValueKey(2),
          date: _date!,
          eventType: _eventType,
          guests: _guests.text,
          venue: _venue.text,
          notes: _notes.text,
          vendor: widget.vendor,
          service: widget.service,
        ),
    };
  }

  void _handleNext() async {
    if (_step == 0) {
      if (_date == null) {
        _snack('Please pick an event date');
        return;
      }
      setState(() => _step++);
    } else if (_step == 1) {
      if (_venue.text.trim().isEmpty) {
        _snack('Please enter the venue');
        return;
      }
      final guests = int.tryParse(_guests.text.trim()) ?? 0;
      if (guests <= 0) {
        _snack('Please enter a valid guest count');
        return;
      }
      setState(() => _step++);
    } else {
      await _submit();
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.warning,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(bookingRepoProvider).create(
            serviceId: widget.service?.id ?? '',
            vendorId: widget.vendor?.id,
            eventDate: _date!,
            guestCount: int.tryParse(_guests.text) ?? 0,
            venue: _venue.text.trim(),
            notes: _notes.text.trim(),
            totalAmount: 0,
          );

      // Auto system message to vendor
      if (widget.vendor != null) {
        try {
          await ref.read(messageRepoProvider).send(
                booking.id,
                widget.vendor!.userId,
                '🎉 New booking request!\n'
                'Event: ${_eventType ?? 'Event'}\n'
                'Date: ${Fmt.date(_date!)}\n'
                'Venue: ${_venue.text.trim()}\n'
                'Guests: ${_guests.text}\n'
                '${_notes.text.trim().isNotEmpty ? 'Notes: ${_notes.text.trim()}' : ''}\n\n'
                'Please accept or decline from your dashboard.',
              );
        } catch (_) {}
      }

      // Generate checklist
      try {
        await ref.read(checklistRepoProvider).generateFromTemplate(
              booking.id,
              widget.service?.slug ?? _eventType?.toLowerCase() ?? 'wedding',
            );
      } catch (_) {}

      ref.invalidate(myBookingsProvider);
      if (mounted) context.go('/booking/confirm/${booking.id}');
    } catch (e) {
      if (mounted) _snack('Failed to book: ${e.toString().split('\n').first}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

// ── Step 0: Date + Event Type ─────────────────────────────────────────────────

class _StepDate extends StatelessWidget {
  const _StepDate({
    super.key,
    required this.selected,
    required this.eventType,
    required this.eventTypes,
    required this.onDatePicked,
    required this.onEventType,
  });
  final DateTime? selected;
  final String? eventType;
  final List<String> eventTypes;
  final ValueChanged<DateTime> onDatePicked;
  final ValueChanged<String?> onEventType;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('When is your event?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700))
            .animate()
            .fadeIn()
            .slideY(begin: -0.2),
        const SizedBox(height: 6),
        Text('Pick the date and event type',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.slate))
            .animate()
            .fadeIn(delay: 100.ms),
        const SizedBox(height: 28),

        // Date picker card
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now().add(const Duration(days: 1)),
              lastDate: DateTime.now().add(const Duration(days: 730)),
              initialDate: selected ??
                  DateTime.now().add(const Duration(days: 30)),
              builder: (_, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context)
                      .colorScheme
                      .copyWith(primary: AppColors.violet),
                ),
                child: child!,
              ),
            );
            if (picked != null) onDatePicked(picked);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: selected != null
                  ? const LinearGradient(
                      colors: [AppColors.violet, Color(0xFF9333EA)])
                  : null,
              border: selected == null
                  ? Border.all(color: AppColors.violetMid, width: 1.5)
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: selected != null
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.violetSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.calendar_today_rounded,
                    color: selected != null ? Colors.white : AppColors.violet,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  selected == null ? 'Choose Event Date' : Fmt.date(selected!),
                  style: TextStyle(
                    color: selected != null ? Colors.white : AppColors.charcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  selected == null
                      ? 'Tap to open calendar'
                      : 'Tap to change',
                  style: TextStyle(
                    color: selected != null
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.slate,
                    fontSize: 12,
                  ),
                ),
              ]),
              const Spacer(),
              Icon(Icons.chevron_right_rounded,
                  color:
                      selected != null ? Colors.white : AppColors.slate),
            ]),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

        const SizedBox(height: 28),
        Text('Event type',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            _StepDate._eventTypes.length,
            (i) {
              final t = _StepDate._eventTypes[i];
              final sel = eventType == t;
              return FilterChip(
                label: Text(t),
                selected: sel,
                onSelected: (_) => onEventType(sel ? null : t),
                selectedColor: AppColors.violet,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                    color: sel ? Colors.white : null,
                    fontWeight: sel ? FontWeight.w600 : null),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 300 + i * 50));
            },
          ),
        ),
      ],
    );
  }

  static const List<String> _eventTypes = [
    'Wedding', 'Birthday', 'Corporate', 'Engagement',
    'Anniversary', 'Festival', 'Other',
  ];
}

// ── Step 1: Details ───────────────────────────────────────────────────────────

class _StepDetails extends StatelessWidget {
  const _StepDetails({
    super.key,
    required this.guestsCtrl,
    required this.venueCtrl,
    required this.notesCtrl,
  });
  final TextEditingController guestsCtrl, venueCtrl, notesCtrl;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Event details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700))
            .animate()
            .fadeIn()
            .slideY(begin: -0.2),
        const SizedBox(height: 6),
        Text('Tell us more about your event',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.slate))
            .animate()
            .fadeIn(delay: 80.ms),
        const SizedBox(height: 28),
        _Field(
          label: 'Number of guests',
          hint: 'e.g. 200',
          controller: guestsCtrl,
          icon: Icons.group_rounded,
          keyboardType: TextInputType.number,
          delay: 150,
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Venue',
          hint: 'Venue name or address',
          controller: venueCtrl,
          icon: Icons.location_on_rounded,
          delay: 200,
        ),
        const SizedBox(height: 16),
        _Field(
          label: 'Special requests',
          hint: 'Any special requirements, theme, etc.',
          controller: notesCtrl,
          icon: Icons.notes_rounded,
          maxLines: 4,
          delay: 250,
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.delay = 0,
  });
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20),
          ),
        ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1);
  }
}

// ── Step 2: Review ────────────────────────────────────────────────────────────

class _StepReview extends StatelessWidget {
  const _StepReview({
    super.key,
    required this.date,
    this.eventType,
    required this.guests,
    required this.venue,
    required this.notes,
    this.vendor,
    this.service,
  });
  final DateTime date;
  final String? eventType;
  final String guests, venue, notes;
  final Vendor? vendor;
  final ServicePackage? service;

  @override
  Widget build(BuildContext context) {
    final name = service?.name ?? vendor?.name ?? 'Event';
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Review & confirm',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700))
            .animate()
            .fadeIn()
            .slideY(begin: -0.2),
        const SizedBox(height: 6),
        Text('Everything looks good?',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.slate))
            .animate()
            .fadeIn(delay: 80.ms),
        const SizedBox(height: 28),

        // Free badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Text('100% Free Platform — No Payment Required',
                style: const TextStyle(
                    color: AppColors.success, fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.violetMid),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(name,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.violetSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Free',
                        style: TextStyle(
                            color: AppColors.violet,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _ReviewRow(Icons.calendar_today_rounded, 'Date', Fmt.date(date)),
                if (eventType != null)
                  _ReviewRow(Icons.celebration_rounded, 'Event', eventType!),
                _ReviewRow(Icons.group_rounded, 'Guests', guests),
                _ReviewRow(Icons.location_on_rounded, 'Venue', venue),
                if (notes.isNotEmpty)
                  _ReviewRow(Icons.notes_rounded, 'Notes', notes),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.violetDeep, AppColors.violet]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'After booking, you can chat directly with your vendor through the app.',
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, height: 1.4),
              ),
            ),
          ]),
        ).animate().fadeIn(delay: 250.ms),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow(this.icon, this.label, this.value);
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.violet),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(
                color: AppColors.slate, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ),
      ]),
    );
  }
}
