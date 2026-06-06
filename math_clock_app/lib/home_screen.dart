import 'package:flutter/material.dart';
import 'dart:async';
import 'clock_tabs/world_clock.dart';
import 'clock_tabs/alarms.dart';
import 'clock_tabs/stopwatch.dart';
import 'clock_tabs/timer.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  int    _selectedIndex = 0;
  Timer? _alarmChecker;

  // GlobalKey gives us access to AlarmsTab's state from outside the widget.
  // This lets HomeScreen call checkAlarms() on the alarms tab regardless
  // of which tab is currently visible.
  final GlobalKey<AlarmsTabState> _alarmsKey = GlobalKey<AlarmsTabState>();

  @override
  void initState() {
    super.initState();
    _alarmChecker = Timer.periodic(const Duration(seconds: 30), (_) {
      _alarmsKey.currentState?.checkAlarms();
    });
  }

  @override
  void dispose() {
    _alarmChecker?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    // WHY IndexedStack instead of tabs[_selectedIndex]?
    //
    // With `body: tabs[_selectedIndex]`, Flutter unmounts the widget that
    // was previously visible and mounts the new one. That means the
    // StopwatchTab's State object is destroyed — killing its Timer — every
    // time the user switches away. IndexedStack keeps ALL tab widgets
    // mounted at once (just hidden), so their State objects (and Timers)
    // live for the entire app session.
    //
    // AutomaticKeepAliveClientMixin in each tab also helps, but
    // IndexedStack is simpler and more reliable for this use-case.

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const WorldClockTab(),
          AlarmsTab(key: _alarmsKey),
          const StopwatchTab(),
          const TimerTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap:        _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.public),                    label: 'World Clock'),
          BottomNavigationBarItem(
              icon: Icon(Icons.alarm),                     label: 'Alarms'),
          BottomNavigationBarItem(
              icon: Icon(Icons.timer_outlined),            label: 'Stopwatch'),
          BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_bottom_outlined), label: 'Timer'),
        ],
      ),
    );
  }
}