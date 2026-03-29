import 'package:flutter/material.dart';
import 'studio_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  // We will build these three screens next
  final List<Widget> _screens = [
    StudioScreen(),
    ProjectsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic_external_on), label: 'Studio'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_special), label: 'Saved'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
