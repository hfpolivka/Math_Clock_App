import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const ClockApp());
}


class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(           // Imported to define the framework for the entire app
      // App title
      title: 'Clock',
      // Remove red "DEBUG" banner in emulator
      debugShowCheckedModeBanner: false,

      // Overall app theme
      theme: ThemeData(
        // General theme colors
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          surface: Color(0xFF1C1C1E),
        ),

        // Bottom navigation bar theme (4 icons)
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          // Bottom nav bar colors
          backgroundColor: Color(0xFF1C1C1E),
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,

          // Keep all 4 icons visible
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const HomeScreen(),     // The first screen shown when the app opens
    );
  }
}