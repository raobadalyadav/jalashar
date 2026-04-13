import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.bookingId, required this.receiverId});
  final String bookingId;
  final String receiverId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(supabaseClientProvider).auth.currentUser?.id;
    final stream = ref.watch(messageRepoProvider).stream(widget.bookingId);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: stream,
              builder: (_, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snap.data!;
                return ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.senderId == me;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: mine ? AppColors.saffron : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.content,
                                style: TextStyle(
                                    color: mine ? Colors.white : Colors.black87)),
                            const SizedBox(height: 2),
                            Text(Fmt.dateTime(m.createdAt),
                                style: TextStyle(
                                    fontSize: 10,
                                    color: mine ? Colors.white70 : Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () async {
                    if (_text.text.trim().isEmpty) return;
                    await ref
                        .read(messageRepoProvider)
                        .send(widget.bookingId, widget.receiverId, _text.text.trim());
                    _text.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
