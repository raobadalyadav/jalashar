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
        label: const Text('New ticket'),
      ),
      body: tickets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) => list.isEmpty
            ? const EmptyState(
                icon: Icons.support_agent,
                title: 'No tickets yet',
                subtitle: "Tap the + button if you need help",
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myTicketsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
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
    String priority = 'normal';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(builder: (ctx, setState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('New support ticket',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Describe the issue'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: ['low', 'normal', 'high', 'urgent']
                    .map((p) => ChoiceChip(
                          label: Text(p),
                          selected: priority == p,
                          onSelected: (_) => setState(() => priority = p),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () async {
                  if (subject.text.isEmpty || message.text.isEmpty) return;
                  try {
                    await ref.read(supportRepoProvider).create(
                          subject: subject.text,
                          message: message.text,
                          priority: priority,
                        );
                    ref.invalidate(myTicketsProvider);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      AppSnack.success(ctx, 'Ticket created');
                    }
                  } catch (e) {
                    if (ctx.mounted) AppSnack.error(ctx, e.toString());
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.t});
  final SupportTicket t;

  Color _statusColor() => switch (t.status) {
        'open' => AppColors.saffron,
        'in_progress' => Colors.blue,
        'resolved' => AppColors.success,
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
            Row(children: [
              Expanded(
                child: Text(t.subject,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              StatusBadge(label: t.status, color: _statusColor()),
            ]),
            const SizedBox(height: 6),
            Text(t.message,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 8),
            Text(Fmt.dateTime(t.createdAt),
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
