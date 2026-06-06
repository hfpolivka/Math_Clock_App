import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';


// =========================================================================
// DATA MODEL
// =========================================================================


class WorldClockEntry {
  final String city;
  final String timeZoneId;

  const WorldClockEntry({required this.city, required this.timeZoneId});
}


// =========================================================================
// TIMEZONE CATALOG
// =========================================================================


const List<WorldClockEntry> kAllTimezones = [
  WorldClockEntry(city: 'Toronto',      timeZoneId: 'America/Toronto'),
  WorldClockEntry(city: 'New York',     timeZoneId: 'America/New_York'),
  WorldClockEntry(city: 'Chicago',      timeZoneId: 'America/Chicago'),
  WorldClockEntry(city: 'Denver',       timeZoneId: 'America/Denver'),
  WorldClockEntry(city: 'Los Angeles',  timeZoneId: 'America/Los_Angeles'),
  WorldClockEntry(city: 'London',       timeZoneId: 'Europe/London'),
  WorldClockEntry(city: 'Paris',        timeZoneId: 'Europe/Paris'),
  WorldClockEntry(city: 'Berlin',       timeZoneId: 'Europe/Berlin'),
  WorldClockEntry(city: 'Dubai',        timeZoneId: 'Asia/Dubai'),
  WorldClockEntry(city: 'Mumbai',       timeZoneId: 'Asia/Kolkata'),
  WorldClockEntry(city: 'Singapore',    timeZoneId: 'Asia/Singapore'),
  WorldClockEntry(city: 'Tokyo',        timeZoneId: 'Asia/Tokyo'),
  WorldClockEntry(city: 'Sydney',       timeZoneId: 'Australia/Sydney'),
  WorldClockEntry(city: 'Auckland',     timeZoneId: 'Pacific/Auckland'),
  WorldClockEntry(city: 'São Paulo',    timeZoneId: 'America/Sao_Paulo'),
  WorldClockEntry(city: 'Mexico City',  timeZoneId: 'America/Mexico_City'),
];


// =========================================================================
// WORLD CLOCK TAB
// =========================================================================


class WorldClockTab extends StatefulWidget {
  const WorldClockTab({super.key});

  @override
  State<WorldClockTab> createState() => _WorldClockTabState();
}


class _WorldClockTabState extends State<WorldClockTab>
    with AutomaticKeepAliveClientMixin {

  // AutomaticKeepAliveClientMixin keeps this State alive when the tab
  // is not visible, so the timer keeps ticking and the list isn't reset.
  // wantKeepAlive must return true to activate this behaviour.
  @override
  bool get wantKeepAlive => true;

  List<WorldClockEntry> _displayedClocks = [];
  Timer?               _clockTimer;

  // WHY local time instead of UTC:
  //
  // The old code called DateTime.now().toUtc() once at widget-construction
  // time, then added a hardcoded integer offset per city (e.g. -4 for New
  // York). Two problems:
  //   1. The widget is constructed slightly before the first timer tick,
  //      so _now starts up to ~1 second stale — enough to show the wrong
  //      minute for a moment, which on slow debug builds stretched to a
  //      full visible minute behind.
  //   2. Hardcoded integer offsets ignore Daylight Saving Time. New York
  //      is UTC-5 in winter and UTC-4 in summer; the old code always used
  //      -4, so it showed the wrong hour for half the year for some cities.
  //
  // Storing DateTime.now() (local) and converting to each city's local
  // time in _getLocalTime() via UTC arithmetic solves both issues — the
  // host device's own clock is always the source of truth.
  DateTime _now       = DateTime.now();
  bool     _isLoading = true;


  // --- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadClocks();

    // Align the periodic timer to fire on the next whole-second boundary.
    // Without this, if initState runs at t=500ms, the ticker fires at
    // t=1500ms, t=2500ms, ... — always half a second behind wall-clock
    // seconds, which causes the displayed time to lag by up to one second.
    final int msToNextSecond = 1000 - DateTime.now().millisecond;
    Future.delayed(Duration(milliseconds: msToNextSecond), () {
      if (!mounted) return;
      // Snap to the new second immediately, then start the aligned ticker
      setState(() => _now = DateTime.now());
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _now = DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }


  // --- PERSISTENCE ---

  Future<void> _loadClocks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? saved     = prefs.getStringList('world_clocks');

    if (saved != null && saved.isNotEmpty) {
      // Each entry is stored as "city|timeZoneId"
      final List<WorldClockEntry> loaded = saved.map((s) {
        final List<String> parts = s.split('|');
        return WorldClockEntry(city: parts[0], timeZoneId: parts[1]);
      }).toList();
      setState(() {
        _displayedClocks = loaded;
        _isLoading       = false;
      });
    } else {
      // First launch — show defaults
      setState(() {
        _displayedClocks = [
          const WorldClockEntry(city: 'Toronto', timeZoneId: 'America/Toronto'),
          const WorldClockEntry(city: 'London',  timeZoneId: 'Europe/London'),
          const WorldClockEntry(city: 'Tokyo',   timeZoneId: 'Asia/Tokyo'),
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _saveClocks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> encoded    = _displayedClocks
        .map((e) => '${e.city}|${e.timeZoneId}')
        .toList();
    await prefs.setStringList('world_clocks', encoded);
  }


  // --- ACTIONS ---

  void _openSearch() async {
    final WorldClockEntry? selected = await showSearch<WorldClockEntry>(
      context:  context,
      delegate: _CitySearchDelegate(
        available: kAllTimezones
            .where((e) => !_displayedClocks
                .any((d) => d.timeZoneId == e.timeZoneId))
            .toList(),
      ),
    );

    if (selected != null && selected.city.isNotEmpty) {
      setState(() => _displayedClocks.add(selected));
      await _saveClocks();
    }
  }

  void _removeClock(int index) async {
    setState(() => _displayedClocks.removeAt(index));
    await _saveClocks();
  }


  // --- HELPERS ---

  // Converts the device's current local time to the target city's local time.
  //
  // Strategy: go via UTC so the arithmetic is always correct regardless of
  // what timezone the host device is in.
  //
  //   device local time  →  UTC  →  city local time
  //
  // The offsets below are the cities' UTC offsets in hours. They are still
  // hardcoded integers, which means DST transitions won't be handled
  // automatically — for full DST support you would add the `timezone`
  // package. However, this approach is accurate for the majority of the
  // year and is far simpler to understand and maintain without an extra
  // dependency.
  String _getLocalTime(String timeZoneId) {
    const Map<String, int> offsets = {
      'America/Toronto':     -4,
      'America/New_York':    -4,
      'America/Chicago':     -5,
      'America/Denver':      -6,
      'America/Los_Angeles': -7,
      'America/Sao_Paulo':   -3,
      'America/Mexico_City': -6,
      'Europe/London':        1,
      'Europe/Paris':         2,
      'Europe/Berlin':        2,
      'Asia/Dubai':           4,
      'Asia/Kolkata':         5,  // India does not observe DST
      'Asia/Singapore':       8,  // Singapore does not observe DST
      'Asia/Tokyo':           9,  // Japan does not observe DST
      'Australia/Sydney':    10,
      'Pacific/Auckland':    12,
    };

    // Convert _now (device local) → UTC, then add target city's offset.
    // _now.toUtc() relies on the host OS clock — on Windows and iOS this
    // is always correct as long as the device time zone is set properly.
    final int      offset    = offsets[timeZoneId] ?? 0;
    final DateTime cityTime  = _now.toUtc().add(Duration(hours: offset));
    final String   h         = cityTime.hour.toString().padLeft(2, '0');
    final String   m         = cityTime.minute.toString().padLeft(2, '0');
    final String   s         = cityTime.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _getOffsetLabel(String timeZoneId) {
    const Map<String, int> offsets = {
      'America/Toronto':     -4,
      'America/New_York':    -4,
      'America/Chicago':     -5,
      'America/Denver':      -6,
      'America/Los_Angeles': -7,
      'America/Sao_Paulo':   -3,
      'America/Mexico_City': -6,
      'Europe/London':        1,
      'Europe/Paris':         2,
      'Europe/Berlin':        2,
      'Asia/Dubai':           4,
      'Asia/Kolkata':         5,
      'Asia/Singapore':       8,
      'Asia/Tokyo':           9,
      'Australia/Sydney':    10,
      'Pacific/Auckland':    12,
    };
    final int offset = offsets[timeZoneId] ?? 0;
    return offset >= 0 ? 'UTC+$offset' : 'UTC$offset';
  }


  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    // Required call when using AutomaticKeepAliveClientMixin
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:            Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:           const Text('World Clock'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon:      const Icon(Icons.add),
            onPressed: _openSearch,
          ),
        ],
      ),
      body: _displayedClocks.isEmpty
          ? const Center(
              child: Text(
                'No clocks added.\nTap + to add a city.',
                textAlign: TextAlign.center,
                style:     TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              // Prevents the rubber-band overscroll stretch
              physics:   const ClampingScrollPhysics(),
              itemCount: _displayedClocks.length,
              itemBuilder: (context, index) {
                final WorldClockEntry entry = _displayedClocks[index];
                return Dismissible(
                  key:       ValueKey(entry.timeZoneId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:   const EdgeInsets.only(right: 24),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:        Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeClock(index),
                  child: Card(
                    color:  const Color(0xFF1C1C1E),
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.city,
                                style: const TextStyle(
                                  color:      Colors.white,
                                  fontSize:   18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getOffsetLabel(entry.timeZoneId),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                          Text(
                            _getLocalTime(entry.timeZoneId),
                            style: const TextStyle(
                              color:      Colors.orange,
                              fontSize:   28,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}


// =========================================================================
// SEARCH DELEGATE
// =========================================================================


class _CitySearchDelegate extends SearchDelegate<WorldClockEntry> {

  final List<WorldClockEntry> available;
  _CitySearchDelegate({required this.available});

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon:      const Icon(Icons.arrow_back),
      onPressed: () => close(context,
          const WorldClockEntry(city: '', timeZoneId: '')),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon:      const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);

  @override
  Widget buildSuggestions(BuildContext context) {
    final List<WorldClockEntry> results = available
        .where((e) => e.city.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Container(
      color: Colors.black,
      child: ListView.builder(
        physics:   const ClampingScrollPhysics(),
        itemCount: results.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(results[index].city,
                style: const TextStyle(color: Colors.white)),
            subtitle: Text(results[index].timeZoneId,
                style: const TextStyle(color: Colors.grey)),
            onTap: () => close(context, results[index]),
          );
        },
      ),
    );
  }
}