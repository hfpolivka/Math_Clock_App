import 'package:flutter/material.dart';

// Import various tab pages
import 'clock_tabs/world_clock.dart';
import 'clock_tabs/alarms.dart';
import 'clock_tabs/stopwatch.dart';
import 'clock_tabs/timer.dart';


// The Stateful Widget for the home screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  // Connect the Stateful Widget to its State object (createState())
  State<HomeScreen> createState() => _HomeScreenState();
}

// A private class to this specific file ('_' prefix)
class _HomeScreenState extends State<HomeScreen> {

  // Constant to define which tab is currently selected
  int _selectedIndex = 0;

  // Widgets for each tab statically defined in a list by index
  static const List<Widget> _tabs = [
    WorldClockTab(),
    AlarmsTab(),
    StopwatchTab(),
    TimerTab(),
  ];

  // Functionality for which tab is pressed
  void _onItemTapped(int index) {
    // Update Flutter when data changes, and to rebuild (setState())
    setState(() {
      _selectedIndex = index;     // Update to selected tab's index
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the Widget of the active tab based on index
      body: _tabs[_selectedIndex],

      // Define the functionality of the bottom nav bar
      bottomNavigationBar: BottomNavigationBar(
        // Current page/index
        currentIndex: _selectedIndex,
        // When item is tapped...
        onTap: _onItemTapped,

        // Define items with icons and labels in the bottom nav bar
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'World Clock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alarm),
            label: 'Alarms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            label: 'Stopwatch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hourglass_bottom_outlined),
            label: 'Timer',
          ),
        ],
      ),
    );
  }
}