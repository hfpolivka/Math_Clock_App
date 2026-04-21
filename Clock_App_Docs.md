# Math Clock App Documentation <!-- omit in toc -->

<br>

This project is meant to provide a semi-challenging goal towards learning the Flutter framework to build apps that funtion on mobile, tablet, and desktop devices. The project serves a second purpose of creating a better version of the alarm app I use to practice mental math.

<br>

## Table of Contents <!-- omit in toc -->

- [Prerequisites](#prerequisites)
- [Installing Flutter](#installing-flutter)
- [Set Up an Android Emulator](#set-up-an-android-emulator)
- [Set Up the Flutter Project](#set-up-the-flutter-project)
- [Edit the Flutter Code](#edit-the-flutter-code)
  - [main.dart](#maindart)
  - [home\_screen.dart](#home_screendart)
  - [The clock\_tabs Folder](#the-clock_tabs-folder)
- [Test How the App Runs](#test-how-the-app-runs)
- [](#)

<br>

## Resources <!-- omit in toc -->

+ [Flutter Crash Course Playlist](https://www.youtube.com/watch?v=j_rCDc_X-k8&list=PL4cUxeGkcC9giLVXCHSQmWqlHc9BLXdVx&index=1)
+ [Flutter Layout Cheat Sheet](https://medium.com/flutter-community/flutter-layout-cheat-sheet-5363348d037e)
+ [TMC Flutter Beginner Widgets Cheatsheet](https://www.scribd.com/document/678484299/tmc-flutter-beginner-widgets-cheatsheet?v=0.521)
+ [RESPONSIVE DESIGN | Flutter Tutorial](https://www.youtube.com/watch?v=MrPJBAOzKTQ)
+ [Responsive Dashboard UI | FLUTTER Tutorial](https://www.youtube.com/watch?v=9bo1V9STW2c&t=887s)
+ [Modular App Architecture in Flutter for Custom Software Projects (2025 Edition)](https://www.200oksolutions.com/blog/modular-app-architecture-in-flutter-for-custom-software-projects-2025-edition/)

<br>

## Prerequisites

+ Install Flutter (below)
+ Install [Visual Studio Code](https://code.visualstudio.com/download)
+ Install [Visual Studio](https://visualstudio.microsoft.com/downloads/)
  + Install Flutter extension
  + Install Dart extension (may be included with Flutter ext.)
+ Download and install [Git for Windows](https://git-scm.com/downloads/win)
+ Install [Android Studio for Flutter](https://docs.flutter.dev/platform-integration/android/setup)
+ Main [Android Studio](https://developer.android.com/studio) installation page

<br>

## Installing Flutter

1) Install [Flutter](https://docs.flutter.dev/get-started/custom) from the website.

<br>

2) Download the Flutter SDK:
    + In VSCode, click View (upper-left), then Command Palette.
    + In the text prompt, type "flutter" and select **Flutter: New Project**.
    + A prompt will appear to locate the Flutter SDK on the local computer. Select **Download SDK**.
    + When the "Select Folder for Flutter SDK" dialog displays, choose a location to install Flutter:
      ```bash
      # Current location
      /Users/{user}/dev/{flutter_sdk_will_be_installed_here}

      # Click "Clone Flutter" to install in that location
      ```
      + During installation, a message in VSCode should read "Downloading the Flutter SDK. This may take a few minutes."
        + **NOTE: If it seems the download has hung, click Cancel, then start the installation again.**

<br>

3) Once the installation completes successfully, click **Add SDK to PATH** in the VSCode prompt that appears:
    + Towards the top of the VSCode window, select the **Application** template from the options.
    + Select a file location for the project to be built.
       + **NOTE: This will restart VSCode and open the file with the Flutter project in the Explorer.**
    + It may also be necessary to close and reopen all terminal windows.

<br>

4) To verify that Flutter installed correctly, run the following command in a VSCode terminal:
    ```
    flutter doctor -v
    ```
    + **NOTE: If the command isn't found or there's an error, check out [Flutter installation troubleshooting](https://docs.flutter.dev/install/troubleshoot).**
    + Read through the output and install anything missing (in red) that is deemed necessary for the project.

<br>

## Set Up an Android Emulator

1) Open Android Studio, click the More Actions dropdown on the main page, and select **Virtual Device Manager**.

<br>

2) In the Device Manager window, click the plus sign in the upper-left to add a new device:
   + In the Add Device window, select Phone for the Form Factor, then select an Android device to emulate. Click Next.
     + **NOTE: For smaller devices, the emulator window may be too large. Use older Android devices in this case, or configure to display horizontally.**
   + On the next page, give the machine a name.
   + Click Additional Settings, and configure the device based on preference/restrictions.
   + Click Finish.
   + Click Yes to confirm download.

<br>

3) Once the download completes, the new machine should be ready for use.

<br>

4) Click the play button to the right of the machine's name to start it, and the three dots to manage/reconfigure the machine if necessary.

<br>

## Set Up the Flutter Project

1) Open a terminal and navigate to the file/folder the project will exist in.
   + **NOTE: Do NOT have spaces or special characters in the filenames.**

<br>

2) Run the following command in the terminal to create the project and give it a name:
   ```bash
   flutter create {project_name}
   # In this case, use 'math_clock_app'

   # No spaces or special characters!
   ```

<br>

3) Once the project is created, open it in VSCode:
   + Navigate into the project directory.
   + Run the following command to open the current folder in VSCode:
      ```
      code .
      ```

<br>

4) Install the Flutter and Dart extensions to VSCode if not done already.

<br>

5) Enable the Status Bar if not done already (View > Appearance > Status Bar checked).

<br>

## Edit the Flutter Code

Get familiar with the project file layout:
   + Most files will not be needed. The core files for the application will live in the **/lib** file.
   + Files with a "." in front of them contin configuration files.
   + A majority of the other files are built and used by Flutter under the hood, and rarely have any manual uses. The structure is simply how the software organizes itself.

<br>

### main.dart

1) Open the **main.dart** file (located in `math_clock_app/lib/main.dart`) in VSCode. Delete all of the contents of this file.
   + The **main.dart** file is the core of any Flutter application.
   + The `main()` function will always be run by Dart first, similar to `int main()` in C++ or Java.
   + The `runApp()` function takes a Widget and makes it fill the screen.
   + In the **main.dart** file, add the following:
        ```dart
        import 'package:flutter/material.dart';
        
        void main() {
            runApp(const ClockApp());
        }
        ```

<br>

2) Create a widget for the `ClockApp()` called in the previous step. This will be a Stateless Widget (implying that it will be static and unchanging; "no other states") which will:
   + Returns the `MaterialApp()` function that sets up the entire Flutter framework (navigation, themes, back-button behavior, etc.).
     + This is what is imported in the first line of every **.dart** file.
   + Defines the app's title.
   + Defines the app's theme.
   + Sets the first screen displayed when the app runs.
     + This will also need to be imported to this file, as well as other necessary files.
   + In the **main.dart** file, update to look like the following:
        ```dart
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
        ```
   + The only error that should appear with the code at this state results from the fact that the call to  `HomeScreen()` defined at the bottom of the file doesn't exist yet.
        
<br>

### home_screen.dart

1) In VSCode, create a new file called **home_screen.dart** (located in `math_clock_app/lib/home_screen.dart`). This file will define the general structure of the application, maintaining the navigation bar at the bottom, and changing the content above it.

<br>

2) Create a widget for the `HomeScreen()` called in the **main.dart** file. This will be a Stateful Widget (implying that it will change or adapt over time; "multiple other states") which will:
   + Returns the `State<HomeScreen>` state that maintains which page is currently displayed.
     + The four other pages of the app will be imported alongside the Material.
   + In the **home_screen.dart** file, update to look like the following:
        ```dart
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

            // Constants

            @override
            Widget build(BuildContext context) {
                return Scaffold();
            }
        }
        ```
   + The only errors that should appear with the code at this state, result from the fact that the four imported pages defined at the top of the file don't exist yet.

<br>

3) Define the constants and `Scaffold()` functionality in the private class `_HomeScreenState`. The full **home_screen.dart** file should look like the following:
    ```dart
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
            WorldClockPage(),
            AlarmsPage(),
            StopwatchPage(),
            TimerPage(),
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
    ``` 

<br>

### The clock_tabs Folder

1) In VSCode, create a new folder called **clock_tabs** (located in `math_clock_app/lib/clock_tabs/`). This folder will contain the four other pages of the application and their related files.

<br>

2) In the **clock_tabs** folder, create the **world_clock.dart** file (located in `math_clock_app/lib/clock_tabs/world_clock.dart`), which will handle the functionality for the World Clock page of the application. For now, update the file with the following Stateleses Widget boilerplate:
    ```dart
    import 'package:flutter/material.dart';


    class WorldClockTab extends StatelessWidget {
        const WorldClockTab({super.key});

        @override
        Widget build(BuildContext context) {
            return const Center(
                child: Text('World Clock', style: TextStyle(color: Colors.white)),
            );
        }
    }
    ```

<br>

3) In the **clock_tabs** folder, create the **alarms.dart** file (located in `math_clock_app/lib/clock_tabs/alarms.dart`), which will handle the functionality for the Alarms page of the application. For now, update the file with the following Stateleses Widget boilerplate:
    ```dart
    import 'package:flutter/material.dart';


    class AlarmsTab extends StatelessWidget {
        const AlarmsTab({super.key});

        @override
        Widget build(BuildContext context) {
            return const Center(
            child: Text('Alarms', style: TextStyle(color: Colors.white)),
            );
        }
    }
    ```

<br>

4) In the **clock_tabs** folder, create the **stopwatch.dart** file (located in `math_clock_app/lib/clock_tabs/stopwatch.dart`), which will handle the functionality for the Stopwatch page of the application. For now, update the file with the following Stateleses Widget boilerplate:
    ```dart
    import 'package:flutter/material.dart';


    class StopwatchTab extends StatelessWidget {
        const StopwatchTab({super.key});

        @override
        Widget build(BuildContext context) {
            return const Center(
            child: Text('Stopwatch', style: TextStyle(color: Colors.white)),
            );
        }
    }
    ```

<br>

5) In the **clock_tabs** folder, create the **timer.dart** file (located in `math_clock_app/lib/clock_tabs/timer.dart`), which will handle the functionality for the Timer page of the application. For now, update the file with the following Stateleses Widget boilerplate:
    ```dart
    import 'package:flutter/material.dart';


    class TimerTab extends StatelessWidget {
        const TimerTab({super.key});

        @override
        Widget build(BuildContext context) {
            return const Center(
            child: Text('Timer', style: TextStyle(color: Colors.white)),
            );
        }
    }
    ```

<br>

## Test How the App Runs

1) Connect the Android emulator to VSCode:
   + In the bottom-right of the VSCode window, click the device name (e.g. No Device, Windows, etc.).
   + In the prompt at the top, a list of options should be presented. Click the name of the Android emulator created in the previous section.
   + The emulator window should appear.

<br>

2) Run the Flutter project in the emulator:
   + Navigate to the **main.dart** file (lib > main.dart).
   + On the **main.dart** tab, click the Start Debugging dropdown (icon is a play button with a bug), and select "Run Without Debugging".
     + **NOTE: This must be done through the **main.dart** file, or the Start Debugging option will not be available.**
   + Once the project runs without debugging, the project should appear in the Android emulator with the Flutter icon.
   + The header should read "Flutter Demo Home Page" when it's done setting up, and the functionality is that of a simple button click counter.
   + Use the colored buttons that appear towards the top of the **main.dart** file to manage the application (e.g. stop, restart, etc.).

<br>

3) OR run the Flutter project in the Chrome browser:
   + In the VSCode terminal, run the following:
      ```
      flutter run -d chrome
      ```

<br>

## 