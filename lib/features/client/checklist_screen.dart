import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/content_repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key, required this.bookingId, this.eventType});
  final String bookingId;
  final String? eventType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(checklistProvider(bookingId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Checklist'),
        actions: [
          if (eventType != null)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate from template',
              onPressed: () async {
                try {
                  await ref
                      .read(checklistRepoProvider)
                      .generateFromTemplate(bookingId, eventType!);
                  ref.invalidate(checklistProvider(bookingId));
                  if (context.mounted) {
                    AppSnack.success(context, 'Checklist generated');
                  }
                } catch (e) {
                  if (context.mounted) AppSnack.error(context, e.toString());
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addItem(context, ref),
        child: const Icon(Icons.add),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(error: e),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.checklist,
              title: 'No items yet',
              subtitle: 'Add items manually or tap ✨ to generate',
              action: eventType != null
                  ? FilledButton(
                      onPressed: () async {
                        await ref
                            .read(checklistRepoProvider)
                            .generateFromTemplate(bookingId, eventType!);
                        ref.invalidate(checklistProvider(bookingId));
                      },
                      child: const Text('Auto-generate'),
                    )
                  : null,
            );
          }
          final done = list.where((i) => i.isDone).length;
          final progress = list.isEmpty ? 0.0 : done / list.length;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$done of ${list.length} completed',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.ivory,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.saffron),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final item = list[i];
                  return Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: AppColors.danger,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (_) async {
                      await ref.read(checklistRepoProvider).delete(item.id);
                      ref.invalidate(checklistProvider(bookingId));
                    },
                    child: CheckboxListTile(
                      value: item.isDone,
                      onChanged: (v) async {
                        await ref
                            .read(checklistRepoProvider)
                            .toggle(item.id, v ?? false);
                        ref.invalidate(checklistProvider(bookingId));
                      },
                      title: Text(
                        item.title,
                        style: TextStyle(
                          decoration: item.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: item.isDone ? AppColors.slate : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }

  void _addItem(BuildContext context, WidgetRef ref) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add checklist item'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Book photographer'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (c.text.trim().isEmpty) return;
              await ref.read(checklistRepoProvider).add(bookingId, c.text.trim());
              ref.invalidate(checklistProvider(bookingId));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
