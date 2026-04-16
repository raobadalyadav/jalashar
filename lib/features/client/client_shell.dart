import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories.dart';
import '../../core/ui/widgets.dart';
import 'bookings_tab.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'messages_tab.dart';
import 'profile_tab.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key});
  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _index = 0;

  static const _tabs = [
    HomeTab(),
    ExploreTab(),
    MessagesTab(),
    BookingsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final notifUnread = unreadAsync.valueOrNull ?? 0;
    final convosAsync = ref.watch(myConversationsProvider);
    final msgUnread = convosAsync.valueOrNull
            ?.fold<int>(0, (s, c) => s + c.unread) ??
        0;

    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(index: _index, children: _tabs),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: 'nav.home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore_rounded),
            label: 'nav.explore'.tr(),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: msgUnread > 0,
              label: Text(msgUnread > 9 ? '9+' : '$msgUnread'),
              child: const Icon(Icons.chat_bubble_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: msgUnread > 0,
              label: Text(msgUnread > 9 ? '9+' : '$msgUnread'),
              child: const Icon(Icons.chat_bubble_rounded),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: const Icon(Icons.event_note_outlined),
            selectedIcon: const Icon(Icons.event_note_rounded),
            label: 'nav.bookings'.tr(),
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: notifUnread > 0,
              label: Text(notifUnread > 9 ? '9+' : '$notifUnread'),
              child: const Icon(Icons.person_outline_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: notifUnread > 0,
              label: Text(notifUnread > 9 ? '9+' : '$notifUnread'),
              child: const Icon(Icons.person_rounded),
            ),
            label: 'nav.profile'.tr(),
          ),
        ],
      ),
    );
  }
}
