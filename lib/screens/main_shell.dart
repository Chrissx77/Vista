import 'package:flutter/material.dart';
import 'package:vista/screens/points_list_page.dart';
import 'package:vista/screens/profile_tab_page.dart';

/// Home dopo login: navigazione inferiore tra lista punti e profilo.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.pointsListTitle});

  final String pointsListTitle;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PointsListPage(title: widget.pointsListTitle),
          const ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.landscape_outlined),
            selectedIcon: Icon(Icons.landscape),
            label: 'Punti',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }
}
