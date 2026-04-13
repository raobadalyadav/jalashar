import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'bookings_tab.dart';
import 'explore_tab.dart';
import 'home_tab.dart';
import 'profile_tab.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _index = 0;

  final _tabs = const [
    HomeTab(),
    ExploreTab(),
    BookingsTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: 'nav.profile'.tr()),
        ],
      ),
    );
  }
}
