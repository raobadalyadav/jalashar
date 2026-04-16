import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/repositories.dart';
import 'bookings_tab.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
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
    BookingsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(notificationUnreadCountProvider);
    final unread = unreadAsync.valueOrNull ?? 0;

    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home),
              label: 'nav.home'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.explore_outlined),
              selectedIcon: const Icon(Icons.explore),
              label: 'nav.explore'.tr()),
          NavigationDestination(
              icon: const Icon(Icons.event_note_outlined),
              selectedIcon: const Icon(Icons.event_note),
              label: 'nav.bookings'.tr()),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: unread > 0,
                label: unread > 9
                    ? const Text('9+')
                    : Text('$unread'),
                child: const Icon(Icons.person_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: unread > 0,
                label: unread > 9
                    ? const Text('9+')
                    : Text('$unread'),
                child: const Icon(Icons.person),
              ),
              label: 'nav.profile'.tr()),
        ],
      ),
    );
  }
}
