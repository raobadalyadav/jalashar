import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/extra_repositories.dart';
import '../../core/data/repositories.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

const _quickReplies = [
  "Thank you! I'll confirm shortly.",
  "I'm available on that date.",
  'Please call me to discuss details.',
  "I'll contact you 2 days before the event.",
  'Could you share more details?',
  'Payment is to be done directly.',
];

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen(
      {super.key, required this.bookingId, required this.receiverId});
  final String bookingId;
  final String receiverId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _text = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _showQuickReplies = false;

  @override
  void dispose() {
    _text.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markRead(String myId) async {
    try {
      await ref.read(messageRepoProvider).markAllRead(widget.bookingId, myId);
    } catch (_) {}
  }

  Future<void> _send(String myId, {String? imageUrl}) async {
    final content = _text.text.trim();
    if (content.isEmpty && imageUrl == null) return;
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await ref.read(messageRepoProvider).send(
            widget.bookingId,
            widget.receiverId,
            content.isEmpty ? '📷 Image' : content,
            imageUrl: imageUrl,
          );
      _text.clear();
      setState(() => _showQuickReplies = false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickImage(String myId) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 75);
    if (file == null) return;

    setState(() => _sending = true);
    try {
      final url = await ref
          .read(storageRepoProvider)
          .uploadChatImage(File(file.path));
      await _send(myId, imageUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Image failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
    final stream = ref.watch(messageRepoProvider).stream(widget.bookingId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.quickreply_outlined,
              color: _showQuickReplies ? AppColors.violet : null,
            ),
            tooltip: 'Quick replies',
            onPressed: () =>
                setState(() => _showQuickReplies = !_showQuickReplies),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick reply chips
          if (_showQuickReplies)
            Container(
              color: context.softSurface,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _quickReplies
                    .map((r) => ActionChip(
                          label: Text(r,
                              style: const TextStyle(fontSize: 12)),
                          onPressed: () {
                            _text.text = r;
                            setState(() => _showQuickReplies = false);
                          },
                          backgroundColor: context.softSurface,
                          side: BorderSide(
                              color: AppColors.violetMid),
                        ))
                    .toList(),
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: stream,
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data!;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _markRead(me));
                _scrollToBottom();

                if (msgs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\nSay hello! 👋',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.senderId == me;
                    final showDate = i == 0 ||
                        !_sameDay(msgs[i - 1].createdAt, m.createdAt);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showDate) _DateDivider(date: m.createdAt),
                        _Bubble(
                          message: m,
                          isMine: mine,
                          showReadReceipt: mine &&
                              i == msgs.lastIndexWhere(
                                  (x) => x.senderId == me),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(children: [
                IconButton(
                  onPressed: _sending ? null : () => _pickImage(me),
                  icon: const Icon(Icons.image_outlined),
                  color: AppColors.violet,
                  tooltip: 'Send image',
                ),
                Expanded(
                  child: TextField(
                    controller: _text,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(me),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton.filled(
                    onPressed: _sending ? null : () => _send(me),
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.violet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    String label;
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      label = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      label = 'Yesterday';
    } else {
      label = Fmt.dayMonth(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(fontSize: 11, color: AppColors.slate)),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.showReadReceipt,
  });
  final Message message;
  final bool isMine;
  final bool showReadReceipt;

  @override
  Widget build(BuildContext context) {
    final hasImage = message.imageUrl != null;
    final hasText = message.content.isNotEmpty &&
        message.content != '📷 Image';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.violet : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (hasImage)
              GestureDetector(
                onTap: () => _openImage(context, message.imageUrl!),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(
                    height: 180,
                    color: isMine
                        ? AppColors.violetDeep
                        : Colors.grey.shade300,
                    child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (c, u, e) => Container(
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasText)
                    Text(
                      message.content,
                      style: TextStyle(
                          color: isMine ? Colors.white : Colors.black87,
                          fontSize: 14),
                    ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Fmt.dateTime(message.createdAt),
                        style: TextStyle(
                            fontSize: 10,
                            color: isMine ? Colors.white70 : Colors.black45),
                      ),
                      if (showReadReceipt) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead
                              ? Colors.white
                              : Colors.white60,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String url) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (ctx, a, b) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    ));
  }
}
