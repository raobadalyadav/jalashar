import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/data/extra_repositories.dart';
import '../../core/theme/app_theme.dart';

class GuestInviteScreen extends ConsumerStatefulWidget {
  const GuestInviteScreen({super.key, required this.bookingId});
  final String bookingId;

  @override
  ConsumerState<GuestInviteScreen> createState() => _GuestInviteScreenState();
}

class _GuestInviteScreenState extends ConsumerState<GuestInviteScreen> {
  final _eventNameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  DateTime? _eventDate;
  bool _loading = false;
  GuestInvite? _invite;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _eventNameCtrl.dispose();
    _venueCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final invite = await ref
          .read(guestInviteRepoProvider)
          .getForBooking(widget.bookingId);
      if (mounted && invite != null) {
        setState(() {
          _invite = invite;
          _eventNameCtrl.text = invite.eventName ?? '';
          _venueCtrl.text = invite.venue ?? '';
          _messageCtrl.text = invite.message ?? '';
          _eventDate = invite.eventDate;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _generate() async {
    final ctx = context;
    if (_eventNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Please enter event name')));
      return;
    }
    if (_venueCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Please enter venue')));
      return;
    }
    if (_eventDate == null) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Please pick event date')));
      return;
    }
    setState(() => _loading = true);
    try {
      final invite = await ref.read(guestInviteRepoProvider).create(
            bookingId: widget.bookingId,
            eventName: _eventNameCtrl.text.trim(),
            eventDate: _eventDate!,
            venue: _venueCtrl.text.trim(),
            message: _messageCtrl.text.trim().isEmpty
                ? null
                : _messageCtrl.text.trim(),
          );
      if (mounted) setState(() => _invite = invite);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _inviteUrl => 'https://jalashar.in/invite/${_invite!.code}';

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _inviteUrl));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Link copied!')));
  }

  Future<void> _shareWhatsApp() async {
    final inv = _invite!;
    final msg = Uri.encodeComponent(
      "You're invited to ${inv.eventName ?? 'my event'}!\n\n"
      "Date: ${inv.eventDate != null ? _fmtDate(inv.eventDate!) : 'TBD'}\n"
      "Venue: ${inv.venue ?? 'TBD'}\n"
      "${inv.message != null ? '\n${inv.message}\n' : ''}"
      "\nView & RSVP: $_inviteUrl",
    );
    await launchUrl(
      Uri.parse("https://wa.me/?text=$msg"),
      mode: LaunchMode.externalApplication,
    );
  }

  void _shareGeneric() {
    final inv = _invite!;
    Share.share(
      "You're invited to ${inv.eventName ?? 'my event'}!\n\n"
      "Date: ${inv.eventDate != null ? _fmtDate(inv.eventDate!) : 'TBD'}\n"
      "Venue: ${inv.venue ?? 'TBD'}\n"
      "${inv.message != null ? '\n${inv.message}\n' : ''}"
      "\nView & RSVP: $_inviteUrl",
      subject: "You're invited!",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Invites')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_invite == null) ...[
                    _buildForm(),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _generate,
                      child: const Text('Generate Invite Link'),
                    ),
                  ] else ...[
                    _buildInviteCard(),
                    const SizedBox(height: 20),
                    _buildShareButtons(),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => setState(() => _invite = null),
                      child: const Text('Edit Details'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Event Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fill in the details to create a shareable invite link for your guests.',
          style: TextStyle(color: AppColors.slate),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _eventNameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Event Name *',
            hintText: 'e.g. Rahul & Priya Wedding',
            prefixIcon: Icon(Icons.celebration_outlined),
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Event Date *',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
            child: Text(
              _eventDate != null ? _fmtDate(_eventDate!) : 'Tap to select',
              style: TextStyle(
                color: _eventDate != null ? null : AppColors.slate,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _venueCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Venue *',
            hintText: 'e.g. Royal Garden Banquet, Mumbai',
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _messageCtrl,
          maxLines: 3,
          maxLength: 300,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Personal Message (optional)',
            hintText: 'We would love for you to join us...',
            prefixIcon: Icon(Icons.message_outlined),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCard() {
    final invite = _invite!;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepMaroon, AppColors.violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepMaroon.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration, color: Colors.white70, size: 16),
              SizedBox(width: 6),
              Text(
                "You're Invited!",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            invite.eventName ?? 'My Event',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          if (invite.eventDate != null)
            _detailRow(Icons.calendar_today_outlined, _fmtDate(invite.eventDate!)),
          if (invite.venue != null)
            _detailRow(Icons.location_on_outlined, invite.venue!),
          if (invite.message != null) ...[
            const SizedBox(height: 8),
            Text(
              invite.message!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Invite code chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _inviteUrl,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: _copyLink,
                  child: const Icon(Icons.copy, color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Invite code badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Code: ${invite.code}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      );

  Widget _buildShareButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _shareWhatsApp,
          icon: const Icon(Icons.chat, size: 18),
          label: const Text('Share via WhatsApp'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _shareGeneric,
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Share via...'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _copyLink,
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Link'),
        ),
      ],
    );
  }
}
