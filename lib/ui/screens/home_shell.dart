import 'package:flutter/material.dart';

import 'archive_screen.dart';
import 'tag_request_list_screen.dart';
import 'truck_list_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    TruckListScreen(),
    TagRequestListScreen(),
    ArchiveScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: scheme.onPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bay Tracker',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping_outlined),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Trucks'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.label_outline),
                selectedIcon: Icon(Icons.label),
                label: Text('Tag Requests'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.archive_outlined),
                selectedIcon: Icon(Icons.archive),
                label: Text('Archive'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: _screens,
            ),
          ),
        ],
      ),
    );
  }
}
