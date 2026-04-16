import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/models/extra_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

class SupportScreen extends ConsumerWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(myTicketsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicket(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Ticket'),
      ),
      body: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.support_agent,
                title: 'No tickets yet',
                subtitle: 'Tap + to raise a support request',
                action: FilledButton.icon(
                  onPressed: () => _showNewTicket(context, ref),
                  icon: const Icon(Icons.add),
                  label: const Text('New Ticket'),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myTicketsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _TicketCard(t: list[i]),
                ),
              ),
      ),
    );
  }

  void _showNewTicket(BuildContext context, WidgetRef ref) {
    final subject = TextEditingController();
    final message = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String priority = 'normal';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('New Support Ticket',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(
                  controller: subject,
                  decoration: const InputDecoration(
                    labelText: 'Subject *',
                    hintText: 'Brief description of your issue',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Subject is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: message,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Describe your issue *',
                    hintText: 'Please provide as much detail as possible',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().length < 10)
                          ? 'Please describe your issue (min 10 chars)'
                          : null,
                ),
                const SizedBox(height: 8),
                const Text('Priority',
                    style: TextStyle(fontSize: 13, color: AppColors.slate)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: ['low', 'normal', 'high', 'urgent']
                      .map((p) => ChoiceChip(
                            label: Text(p.toUpperCase(),
                                style: const TextStyle(fontSize: 11)),
                            selected: priority == p,
                            selectedColor: _priorityColor(p),
                            onSelected: (_) => setState(() => priority = p),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    try {
                      await ref.read(supportRepoProvider).create(
                            subject: subject.text.trim(),
                            message: message.text.trim(),
                            priority: priority,
                          );
                      ref.invalidate(myTicketsProvider);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        AppSnack.success(ctx, 'Ticket submitted! We will respond shortly.');
                      }
                    } catch (e) {
                      if (ctx.mounted) AppSnack.error(ctx, e.toString());
                    }
                  },
                  child: const Text('Submit Ticket'),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Color _priorityColor(String p) => switch (p) {
        'low' => AppColors.success,
        'high' => AppColors.warning,
        'urgent' => AppColors.danger,
        _ => AppColors.info,
      };
}

// ── Ticket card ─────────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.t});
  final SupportTicket t;

  Color _statusColor() => switch (t.status) {
        'open' => AppColors.violet,
        'in_progress' => Colors.blue,
        'resolved' => AppColors.success,
        _ => AppColors.slate,
      };

  IconData _statusIcon() => switch (t.status) {
        'open' => Icons.inbox_outlined,
        'in_progress' => Icons.pending_outlined,
        'resolved' => Icons.check_circle_outline_rounded,
        _ => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TicketDetailScreen(ticket: t)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor().withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_statusIcon(),
                      color: _statusColor(), size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(t.subject,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                StatusBadge(label: t.status, color: _statusColor()),
              ]),
              const SizedBox(height: 8),
              Text(t.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.slate, fontSize: 13)),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.access_time,
                    size: 12, color: AppColors.slate),
                const SizedBox(width: 4),
                Text(Fmt.dateTime(t.createdAt),
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.priority == 'urgent' || t.priority == 'high'
                        ? AppColors.danger.withValues(alpha: 0.1)
                        : context.midSurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: t.priority == 'urgent' || t.priority == 'high'
                          ? AppColors.danger
                          : AppColors.violet,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.slate),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ticket detail / chat ─────────────────────────────────────────────────────

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({super.key, required this.ticket});
  final SupportTicket ticket;

  @override
  ConsumerState<TicketDetailScreen> createState() =>
      _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(supportMsgRepoProvider)
          .send(widget.ticket.id, text);
      _ctrl.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Color _statusColor() => switch (widget.ticket.status) {
        'open' => AppColors.violet,
        'in_progress' => Colors.blue,
        'resolved' => AppColors.success,
        _ => AppColors.slate,
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final msgStream =
        ref.watch(supportMsgRepoProvider).stream(widget.ticket.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ticket.subject,
            style: const TextStyle(fontSize: 15)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _statusColor().withValues(alpha: 0.3)),
            ),
            child: Text(
              widget.ticket.status.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(
                  color: _statusColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Original message
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E1B3A)
                  : AppColors.violetSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.inbox_outlined,
                      size: 14, color: AppColors.violet),
                  const SizedBox(width: 6),
                  Text('Original Request',
                      style: const TextStyle(
                          color: AppColors.violet,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 6),
                Text(widget.ticket.message,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Text(Fmt.dateTime(widget.ticket.createdAt),
                    style: const TextStyle(
                        color: AppColors.slate, fontSize: 11)),
              ],
            ),
          ),

          const Divider(height: 1),

          // Message thread
          Expanded(
            child: StreamBuilder<List<SupportMessage>>(
              stream: msgStream,
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 40,
                                color: AppColors.slate.withValues(alpha: 0.4)),
                            const SizedBox(height: 8),
                            const Text('No replies yet',
                                style: TextStyle(
                                    color: AppColors.slate, fontSize: 13)),
                            const SizedBox(height: 4),
                            const Text('Our team will respond shortly',
                                style: TextStyle(
                                    color: AppColors.slate, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) => _MsgBubble(msg: msgs[i]),
                );
              },
            ),
          ),

          // Reply input (only if ticket is not resolved)
          if (widget.ticket.status != 'resolved')
            Container(
              padding: EdgeInsets.fromLTRB(
                12,
                8,
                12,
                MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                    top: BorderSide(
                        color:
                            AppColors.violetMid.withValues(alpha: 0.5))),
              ),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: 'Add a follow-up message...',
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white))
                      : const Icon(Icons.send_rounded),
                ),
              ]),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.success.withValues(alpha: 0.08),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 16),
                  SizedBox(width: 6),
                  Text('This ticket has been resolved',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MsgBubble extends StatelessWidget {
  const _MsgBubble({required this.msg});
  final SupportMessage msg;

  @override
  Widget build(BuildContext context) {
    final isAdmin = msg.isAdmin;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isAdmin ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isAdmin) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                  color: AppColors.violet, shape: BoxShape.circle),
              child: const Icon(Icons.support_agent,
                  color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isAdmin
                    ? (isDark
                        ? const Color(0xFF2D2B50)
                        : AppColors.violetMid)
                    : AppColors.violet,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isAdmin ? 4 : 16),
                  bottomRight: Radius.circular(isAdmin ? 16 : 4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.body,
                    style: TextStyle(
                      color: isAdmin
                          ? (isDark ? Colors.white : AppColors.charcoal)
                          : Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Fmt.dateTime(msg.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isAdmin
                          ? AppColors.slate
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
