import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  final _guests = TextEditingController(text: '100');
  final _venue = TextEditingController();
  final _notes = TextEditingController();
  bool _submitting = false;

  double get _total => widget.service?.basePrice ?? widget.vendor?.basePrice ?? 25000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () async {
          if (_step == 0 && _date == null) return;
          if (_step == 1 && _venue.text.isEmpty) return;
          if (_step == 3) {
            await _submit();
            return;
          }
          setState(() => _step++);
        },
        onStepCancel: _step == 0 ? null : () => setState(() => _step--),
        controlsBuilder: (c, d) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(children: [
            FilledButton(
              onPressed: _submitting ? null : d.onStepContinue,
              child: Text(_step == 3 ? 'Pay & Confirm' : 'Next'),
            ),
            const SizedBox(width: 12),
            if (d.onStepCancel != null)
              TextButton(onPressed: d.onStepCancel, child: const Text('Back')),
          ]),
        ),
        steps: [
          Step(
            title: const Text('Date'),
            isActive: _step >= 0,
            content: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: Text(_date == null ? 'Pick event date' : Fmt.date(_date!)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) setState(() => _date = picked);
                  },
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Details'),
            isActive: _step >= 1,
            content: Column(
              children: [
                TextField(
                  controller: _guests,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Guest count',
                    prefixIcon: Icon(Icons.group),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _venue,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Special notes',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              ],
            ),
          ),
          Step(
            title: const Text('Summary'),
            isActive: _step >= 2,
            content: Card(
              color: AppColors.ivory,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.service?.name ?? widget.vendor?.name ?? 'Package',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    if (_date != null) Text('Date: ${Fmt.date(_date!)}'),
                    Text('Guests: ${_guests.text}'),
                    Text('Venue: ${_venue.text}'),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(Fmt.currency(_total),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.deepMaroon)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('30% advance: ${Fmt.currency(_total * 0.3)}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          ),
          Step(
            title: const Text('Payment'),
            isActive: _step >= 3,
            content: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.account_balance_wallet, color: AppColors.saffron),
                  title: Text('UPI / Cards / Net Banking'),
                  subtitle: Text('Secure via Razorpay'),
                ),
                if (_submitting) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.service == null) return;
    setState(() => _submitting = true);
    try {
      await ref.read(bookingRepoProvider).create(
            serviceId: widget.service!.id,
            vendorId: widget.vendor?.id,
            eventDate: _date!,
            guestCount: int.tryParse(_guests.text) ?? 0,
            venue: _venue.text,
            notes: _notes.text,
            totalAmount: _total,
          );
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking confirmed!')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
