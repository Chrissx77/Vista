import 'package:flutter/material.dart';
import 'package:vista/screens/add_point_page.dart';
import 'package:vista/screens/points_list_page.dart';
import 'package:vista/screens/profile_tab_page.dart';
import 'package:vista/utility/colors_app.dart';

/// Home dopo login: bottom bar minimal con tre destinazioni.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.pointsListTitle});

  final String pointsListTitle;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onDestinationSelected(int index) {
    if (index == 1) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const AddPointPage()),
      );
      return;
    }
    final mapped = index == 0 ? 0 : 1;
    setState(() => _currentIndex = mapped);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PointsListPage(title: widget.pointsListTitle),
      const ProfileTabPage(),
    ];

    final selectedNavIndex = _currentIndex == 0 ? 0 : 2;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: ColorsApp.surface,
          border: Border(
            top: BorderSide(color: ColorsApp.outline, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedNavIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Esplora',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: 'Aggiungi',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profilo',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
