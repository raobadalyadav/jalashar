import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/data/content_repositories.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/extra_models.dart';
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
  final _couponCtrl = TextEditingController();
  bool _submitting = false;

  Coupon? _appliedCoupon;
  double _couponDiscount = 0;
  String? _couponError;
  bool _checkingCoupon = false;

  double get _baseTotal =>
      widget.service?.basePrice ?? widget.vendor?.basePrice ?? 25000;
  double get _total => (_baseTotal - _couponDiscount).clamp(0, double.infinity);

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _checkingCoupon = true;
      _couponError = null;
    });
    try {
      final coupon = await ref.read(couponRepoProvider).byCode(code);
      if (coupon == null) {
        setState(() => _couponError = 'Invalid or expired coupon');
        return;
      }
      final discount = coupon.applyTo(_baseTotal);
      if (discount == 0) {
        setState(() => _couponError =
            'Minimum order ₹${coupon.minOrder.toStringAsFixed(0)} required');
        return;
      }
      setState(() {
        _appliedCoupon = coupon;
        _couponDiscount = discount;
      });
    } catch (e) {
      setState(() => _couponError = 'Error: $e');
    } finally {
      if (mounted) setState(() => _checkingCoupon = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Booking')),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () async {
          if (_step == 0 && _date == null) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please pick a date')));
            return;
          }
          if (_step == 1 && _venue.text.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter venue')));
            return;
          }
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitting ? null : d.onStepContinue,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(_step == 3 ? 'Pay & Confirm' : 'Next'),
            ),
            const SizedBox(width: 12),
            if (d.onStepCancel != null)
              TextButton(onPressed: d.onStepCancel, child: const Text('Back')),
          ]),
        ),
        steps: [
          // ── Step 0: Date
          Step(
            title: const Text('Event Date'),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now().add(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: _date != null
                          ? AppColors.saffron
                          : Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_month,
                      color:
                          _date != null ? AppColors.saffron : AppColors.slate),
                  const SizedBox(width: 12),
                  Text(
                    _date == null ? 'Tap to pick event date' : Fmt.date(_date!),
                    style: TextStyle(
                      color:
                          _date != null ? AppColors.deepMaroon : AppColors.slate,
                      fontWeight: _date != null ? FontWeight.w600 : null,
                      fontSize: 15,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // ── Step 1: Details
          Step(
            title: const Text('Event Details'),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
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
                    labelText: 'Venue name / address',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Special requests (optional)',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),

          // ── Step 2: Coupon + Summary
          Step(
            title: const Text('Review & Coupon'),
            isActive: _step >= 2,
            state: _step > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Card(
                  color: AppColors.ivory,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.service?.name ??
                              widget.vendor?.name ??
                              'Package',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        _SummaryRow('Date',
                            _date != null ? Fmt.date(_date!) : '—'),
                        _SummaryRow('Guests', _guests.text),
                        _SummaryRow('Venue',
                            _venue.text.isEmpty ? '—' : _venue.text),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Base Price'),
                            Text(Fmt.currency(_baseTotal)),
                          ],
                        ),
                        if (_couponDiscount > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Coupon (${_appliedCoupon!.code})',
                                style: const TextStyle(color: AppColors.success),
                              ),
                              Text(
                                '− ${Fmt.currency(_couponDiscount)}',
                                style:
                                    const TextStyle(color: AppColors.success),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                              Fmt.currency(_total),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.deepMaroon),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '30% advance: ${Fmt.currency(_total * 0.3)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Coupon input
                if (_appliedCoupon == null) ...[
                  Text('Have a coupon?',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _couponCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code',
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                          errorText: _couponError,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _checkingCoupon ? null : _applyCoupon,
                      child: _checkingCoupon
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Apply'),
                    ),
                  ]),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.success),
                    ),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_appliedCoupon!.code,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                            if (_appliedCoupon!.description != null)
                              Text(_appliedCoupon!.description!,
                                  style:
                                      Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          _appliedCoupon = null;
                          _couponDiscount = 0;
                          _couponCtrl.clear();
                        }),
                        child: const Text('Remove'),
                      ),
                    ]),
                  ),
              ],
            ),
          ),

          // ── Step 3: Payment
          Step(
            title: const Text('Payment'),
            isActive: _step >= 3,
            content: Column(
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.account_balance_wallet,
                      color: AppColors.saffron, size: 32),
                  title: Text('UPI / Cards / Net Banking',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Powered by Razorpay · 256-bit SSL encrypted'),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Amount due now'),
                      Text(
                        Fmt.currency(_total * 0.3),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.deepMaroon),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_submitting) const LinearProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (widget.service == null && widget.vendor == null) return;
    setState(() => _submitting = true);
    try {
      final booking = await ref.read(bookingRepoProvider).create(
            serviceId: widget.service?.id ?? '',
            vendorId: widget.vendor?.id,
            eventDate: _date!,
            guestCount: int.tryParse(_guests.text) ?? 0,
            venue: _venue.text,
            notes: _notes.text,
            totalAmount: _total,
          );

      // Apply coupon if present
      if (_appliedCoupon != null) {
        await ref.read(couponRepoProvider).applyToBooking(
              booking.id,
              _appliedCoupon!.id,
              _couponDiscount,
            );
      }

      // Create Razorpay order (30% advance)
      try {
        await ref.read(paymentRepoProvider).createOrder(
              bookingId: booking.id,
              amount: _total * 0.3,
            );
      } catch (_) {}

      // Auto system message to vendor
      if (widget.vendor != null) {
        try {
          await ref.read(messageRepoProvider).send(
                booking.id,
                widget.vendor!.userId,
                '🎉 New booking received!\n'
                'Event Date: ${Fmt.date(_date!)}\n'
                'Venue: ${_venue.text}\n'
                'Guests: ${_guests.text}\n'
                'Total: ${Fmt.currency(_total)}\n\n'
                'Please confirm availability and accept/decline from your dashboard.',
              );
        } catch (_) {}
      }

      // Generate checklist from template if service type known
      try {
        await ref.read(checklistRepoProvider).generateFromTemplate(
              booking.id,
              widget.service?.slug ?? 'wedding',
            );
      } catch (_) {}

      ref.invalidate(myBookingsProvider);
      if (mounted) context.go('/booking/confirm/${booking.id}');
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.slate)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}
