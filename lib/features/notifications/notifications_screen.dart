import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories.dart';
import '../../core/utils/formatters.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('No notifications'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(notificationsProvider),
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: n.isRead
                            ? Colors.grey.shade200
                            : Colors.orange.shade100,
                        child: Icon(
                          n.isRead ? Icons.mark_email_read : Icons.notifications,
                          color: Colors.orange,
                        ),
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight:
                                  n.isRead ? FontWeight.normal : FontWeight.w600)),
                      subtitle: Text(n.body ?? ''),
                      trailing: Text(Fmt.dayMonth(n.createdAt),
                          style: const TextStyle(fontSize: 11)),
                      onTap: () async {
                        await ref.read(notificationRepoProvider).markRead(n.id);
                        ref.invalidate(notificationsProvider);
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }
}
