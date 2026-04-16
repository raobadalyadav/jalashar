import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/data/repositories.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/widgets.dart';
import '../../core/utils/formatters.dart';

class MessagesTab extends ConsumerWidget {
  const MessagesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convos = ref.watch(myConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(myConversationsProvider),
          ),
        ],
      ),
      body: convos.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(5, (_) => const SkeletonCard(height: 72)),
        ),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(myConversationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No conversations yet',
              subtitle:
                  'Book a vendor to start chatting. All chats are free!',
              action: FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Find Vendors'),
              ),
            );
          }

          final withMsgs = list.where((c) => c.lastMsg != null).toList();
          final withoutMsgs = list.where((c) => c.lastMsg == null).toList();
          final sorted = [...withMsgs, ...withoutMsgs];

          return RefreshIndicator(
            color: AppColors.violet,
            onRefresh: () async => ref.invalidate(myConversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: sorted.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 80, endIndent: 16),
              itemBuilder: (_, i) {
                final c = sorted[i];
                return _ConvoTile(convo: c)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: i * 40))
                    .slideX(begin: -0.05);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ConvoTile extends ConsumerWidget {
  const _ConvoTile({required this.convo});
  final ConversationSummary convo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = convo.booking;
    final lastMsg = convo.lastMsg;
    final me = ref.watch(supabaseClientProvider).auth.currentUser?.id ?? '';
    final isMine = lastMsg?.senderId == me;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: _VendorAvatar(vendorId: booking.vendorId),
      title: Row(children: [
        Expanded(
          child: Text(
            'Booking #${booking.id.substring(0, 6).toUpperCase()}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        if (lastMsg != null)
          Text(
            Fmt.timeAgo(lastMsg.createdAt),
            style: const TextStyle(fontSize: 11, color: AppColors.slate),
          ),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Row(children: [
            if (isMine)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Text('You: ',
                    style: TextStyle(
                        color: AppColors.slate, fontSize: 12)),
              ),
            Expanded(
              child: Text(
                lastMsg?.content ?? 'Tap to start chatting →',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      lastMsg == null ? AppColors.violet : AppColors.slate,
                  fontSize: 13,
                  fontStyle: lastMsg == null ? FontStyle.italic : null,
                ),
              ),
            ),
            if (convo.unread > 0)
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  convo.unread > 9 ? '9+' : '${convo.unread}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
          ]),
          const SizedBox(height: 2),
          Text(
            '${booking.status.label} · ${Fmt.date(booking.eventDate)}',
            style: const TextStyle(fontSize: 11, color: AppColors.slate),
          ),
        ],
      ),
      onTap: () {
        if (booking.vendorId == null) return;
        context.push(
            '/chat/${booking.id}/${booking.vendorId}');
      },
    );
  }
}

class _VendorAvatar extends ConsumerWidget {
  const _VendorAvatar({required this.vendorId});
  final String? vendorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (vendorId == null) {
      return _FallbackAvatar(label: '?');
    }
    final vendor = ref.watch(
        FutureProvider.autoDispose(
            (r) => r.watch(vendorRepoProvider).getById(vendorId!)).future);
    return FutureBuilder(
      future: vendor,
      builder: (_, snap) {
        final v = snap.data;
        if (v?.avatarUrl != null) {
          return CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(v!.avatarUrl!),
          );
        }
        return _FallbackAvatar(label: v?.name?.substring(0, 1) ?? 'V');
      },
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18),
      ),
    );
  }
}
