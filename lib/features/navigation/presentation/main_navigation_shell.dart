import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../connections/data/connection_providers.dart';
import '../../encounters/data/encounter_providers.dart';
import '../../chat/data/chat_providers.dart';

/// The primary navigation shell for the application, providing the bottom navigation bar.
class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainNavigationShell> createState() =>
      _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  late int _lastBranchIndex;
  @override
  void initState() {
    super.initState();
    _lastBranchIndex = widget.navigationShell.currentIndex;
  }

  // These are authorized repository reads only. Discovery/location, presence
  // activation and all mutation controllers are intentionally untouched.
  void _refreshSocial(int index) {
    if (index == 0 || index == 2) {
      ref.invalidate(encountersForCurrentUserProvider);
      ref.invalidate(incomingConnectionRequestsProvider);
      ref.invalidate(relationshipProvider);
    }
    if (index == 0 || index == 2) {
      ref.invalidate(connectionsProvider);

      ref.invalidate(chatConversationsProvider);
    }
  }

  void _onTap(int index) {
    if (index == widget.navigationShell.currentIndex) {
      _refreshSocial(index);
    }
    widget.navigationShell.goBranch(
      index,
      // When tapping the current tab again, we return to the root of that branch.
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    if (currentIndex != _lastBranchIndex) {
      _lastBranchIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.navigationShell.currentIndex == currentIndex) {
          _refreshSocial(currentIndex);
        }
      });
    }
    // Use a responsive strategy for labels on narrow devices.
    // At very narrow widths, only show the selected label.
    final bool isNarrow = MediaQuery.sizeOf(context).width < 360;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        height:
            80 +
            (MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0) - 1) *
                24,
        elevation: 0,
        indicatorShape: const StadiumBorder(),
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        labelBehavior: isNarrow
            ? NavigationDestinationLabelBehavior.onlyShowSelected
            : NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Groups',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
