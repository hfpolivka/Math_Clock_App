import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';


// =========================================================================
// ENUMS & CONSTANTS
// =========================================================================


enum TimerState { idle, running, paused, finished }

const List<String> kRingtones = [
  'Default', 'Chime', 'Bell', 'Digital', 'Marimba', 'Radar',
];


// =========================================================================
// DATA MODEL
// =========================================================================


class TimerEntry {
  final String   id;
  final Duration totalDuration;
  final String   label;
  final String   ringtone;

  TimerState state;
  Duration   remaining;
  Timer?     ticker;
  DateTime?  endTime;

  TimerEntry({
    required this.id,
    required this.totalDuration,
    required this.label,
    required this.ringtone,
  })  : state     = TimerState.idle,
        remaining = totalDuration;

  double get progress {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return remaining.inMilliseconds / totalDuration.inMilliseconds;
  }

  String get endTimeLabel {
    final DateTime end = DateTime.now().add(remaining);
    return '${end.hour.toString().padLeft(2, '0')}:'
           '${end.minute.toString().padLeft(2, '0')}';
  }

  String get formattedRemaining {
    final int h = remaining.inHours;
    final int m = remaining.inMinutes % 60;
    final int s = remaining.inSeconds % 60;
    if (h > 0) return '$h:${_pad(m)}:${_pad(s)}';
    return '${_pad(m)}:${_pad(s)}';
  }

  String get totalDurationLabel {
    final int h = totalDuration.inHours;
    final int m = totalDuration.inMinutes % 60;
    final int s = totalDuration.inSeconds % 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0)           return '${h}h';
    if (m > 0 && s > 0)  return '${m}m ${s}s';
    if (m > 0)           return '${m}m';
    return '${s}s';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  String encode() => [
    id,
    totalDuration.inSeconds.toString(),
    remaining.inSeconds.toString(),
    label,
    ringtone,
    state.index.toString(),
    endTime?.millisecondsSinceEpoch.toString() ?? '0',
  ].join('|');

  factory TimerEntry.decode(String s) {
    final List<String> p = s.split('|');
    final TimerEntry entry = TimerEntry(
      id:            p[0],
      totalDuration: Duration(seconds: int.parse(p[1])),
      label:         p[3],
      ringtone:      p[4],
    );
    final TimerState savedState = TimerState.values[int.parse(p[5])];
    final int        endEpoch   = int.parse(p[6]);

    if (savedState == TimerState.running && endEpoch > 0) {
      final int msLeft =
          endEpoch - DateTime.now().millisecondsSinceEpoch;
      if (msLeft <= 0) {
        entry.remaining = Duration.zero;
        entry.state     = TimerState.finished;
      } else {
        entry.remaining = Duration(milliseconds: msLeft);
        entry.state     = TimerState.running;
        entry.endTime   = DateTime.fromMillisecondsSinceEpoch(endEpoch);
      }
    } else {
      entry.remaining = Duration(seconds: int.parse(p[2]));
      entry.state     = savedState;
    }
    return entry;
  }
}


// =========================================================================
// TIMER TAB
// =========================================================================
//
// Layout (iPhone Clock-style):
//   ┌─────────────────────────────┐
//   │  h / m / s  wheels          │  ← always visible at the top
//   │  Label field                │
//   │  Ringtone picker            │
//   │  [ Cancel ]   [ Start ]     │
//   ├─────────────────────────────┤
//   │  Recent Timers              │  ← scrollable section below
//   │  ...entries...              │
//   └─────────────────────────────┘
//
// Everything lives in one CustomScrollView so the wheels + controls
// scroll off naturally when the user scrolls to see recent timers.


class TimerTab extends StatefulWidget {
  const TimerTab({super.key});

  @override
  State<TimerTab> createState() => _TimerTabState();
}


class _TimerTabState extends State<TimerTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  // --- Wheel controllers (hours 0–23, minutes 0–59, seconds 0–59) ---
  final FixedExtentScrollController _hoursCtrl   =
      FixedExtentScrollController(initialItem: 0);
  final FixedExtentScrollController _minutesCtrl =
      FixedExtentScrollController(initialItem: 1);
  final FixedExtentScrollController _secondsCtrl =
      FixedExtentScrollController(initialItem: 0);

  int    _h        = 0;
  int    _m        = 1;
  int    _s        = 0;
  String _label    = '';
  String _ringtone = kRingtones.first;

  // Running/saved timers shown in the "Recent" section
  final List<TimerEntry> _timers    = [];
  bool                   _isLoading = true;

  // Which timer is shown full-screen (expanded view)
  String? _expandedTimerId;


  // --- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadTimers();
  }

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _minutesCtrl.dispose();
    _secondsCtrl.dispose();
    for (final t in _timers) t.ticker?.cancel();
    super.dispose();
  }


  // --- PERSISTENCE ---

  Future<void> _saveTimers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'timers', _timers.map((t) => t.encode()).toList());
  }

  Future<void> _loadTimers() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? raw       = prefs.getStringList('timers');

    if (raw != null && raw.isNotEmpty) {
      final List<TimerEntry> restored =
          raw.map((s) => TimerEntry.decode(s)).toList();
      setState(() => _timers.addAll(restored));

      for (final TimerEntry entry in _timers) {
        if (entry.state == TimerState.running) _resumeTicker(entry);
      }
    }

    setState(() => _isLoading = false);
  }


  // --- TIMER CONTROL ---

  void _resumeTicker(TimerEntry entry) {
    entry.ticker?.cancel();
    entry.ticker = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (entry.remaining.inSeconds <= 1) {
        entry.ticker?.cancel();
        entry.ticker = null;
        setState(() {
          entry.remaining = Duration.zero;
          entry.state     = TimerState.finished;
          entry.endTime   = null;
          _timers.sort((a, b) => a.remaining.compareTo(b.remaining));
        });
        _onTimerFinished(entry);
        await _saveTimers();
      } else {
        setState(() {
          entry.remaining = entry.remaining - const Duration(seconds: 1);
          _timers.sort((a, b) => a.remaining.compareTo(b.remaining));
        });
        await _saveTimers();
      }
    });
  }

  void _startTimer(TimerEntry entry) {
    entry.endTime = DateTime.now().add(entry.remaining);
    setState(() => entry.state = TimerState.running);
    _resumeTicker(entry);
  }

  void _pauseTimer(TimerEntry entry) async {
    entry.ticker?.cancel();
    entry.ticker  = null;
    entry.endTime = null;
    setState(() => entry.state = TimerState.paused);
    await _saveTimers();
  }

  void _resumeTimer(TimerEntry entry) {
    if (entry.state == TimerState.finished) {
      setState(() {
        entry.remaining = entry.totalDuration;
        entry.state     = TimerState.idle;
      });
    }
    _startTimer(entry);
  }

  void _cancelTimer(TimerEntry entry) async {
    entry.ticker?.cancel();
    entry.ticker  = null;
    entry.endTime = null;
    setState(() {
      entry.remaining = entry.totalDuration;
      entry.state     = TimerState.idle;
    });
    await _saveTimers();
  }

  void _deleteTimer(TimerEntry entry) async {
    entry.ticker?.cancel();
    setState(() {
      if (_expandedTimerId == entry.id) _expandedTimerId = null;
      _timers.remove(entry);
    });
    await _saveTimers();
  }

  void _onTimerFinished(TimerEntry entry) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:        SnackBarBehavior.floating,
        backgroundColor: Colors.orange,
        duration:        const Duration(seconds: 6),
        content: Row(
          children: [
            const Icon(Icons.timer, color: Colors.black),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.label.isEmpty
                    ? 'Timer finished!'
                    : '${entry.label} — finished!',
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
            label: 'Dismiss', textColor: Colors.black, onPressed: () {}),
      ),
    );
  }


  // --- CREATE: Start button in the settings section ---

  bool get _isValid => _h > 0 || _m > 0 || _s > 0;

  void _createAndStart() async {
    if (!_isValid) return;
    final TimerEntry entry = TimerEntry(
      id:            DateTime.now().millisecondsSinceEpoch.toString(),
      totalDuration: Duration(hours: _h, minutes: _m, seconds: _s),
      label:         _label,
      ringtone:      _ringtone,
    );
    setState(() => _timers.add(entry));
    _startTimer(entry);
    await _saveTimers();
  }


  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:            Center(child: CircularProgressIndicator()),
      );
    }

    // Show expanded view when a timer card is tapped
    if (_expandedTimerId != null) {
      final TimerEntry? expanded =
          _timers.where((t) => t.id == _expandedTimerId).firstOrNull;
      if (expanded != null) {
        return _ExpandedTimerView(
          key:      ValueKey(expanded.id),
          entry:    expanded,
          onBack:   () => setState(() => _expandedTimerId = null),
          onCancel: () => _cancelTimer(expanded),
          onPause:  () => _pauseTimer(expanded),
          onResume: () => _resumeTimer(expanded),
        );
      }
    }

    // Main screen: settings wheel at top, recent timers below
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:           const Text('Timer'),
        backgroundColor: Colors.black,
      ),
      body: CustomScrollView(
        // CustomScrollView lets us mix fixed-height slivers (wheels)
        // with variable-height list content in one scroll area.
        slivers: [

          // ── SETTINGS SECTION ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [

                // Time wheels
                const SizedBox(height: 12),
                _buildWheels(),
                const SizedBox(height: 24),

                // Label + Ringtone config block
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildConfig(),
                ),
                const SizedBox(height: 24),

                // Cancel / Start buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleButton(
                        label: 'Cancel',
                        // Cancel resets wheels to 0:01:00
                        onPressed: () {
                          setState(() {
                            _h = 0; _m = 1; _s = 0;
                            _label    = '';
                            _ringtone = kRingtones.first;
                          });
                          _minutesCtrl.jumpToItem(1);
                          _hoursCtrl.jumpToItem(0);
                          _secondsCtrl.jumpToItem(0);
                        },
                        color: const Color(0xFF2C2C2E),
                      ),
                      _CircleButton(
                        label:      'Start',
                        onPressed:  _isValid ? _createAndStart : null,
                        color:      const Color(0xFF1A3A1A),
                        labelColor: Colors.green,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(color: Color(0xFF2C2C2E)),

                // Section header for recent timers
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _timers.isEmpty ? 'No recent timers' : 'Recent',
                      style: const TextStyle(
                        color:    Colors.grey,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

              ],
            ),
          ),

          // ── RECENT TIMERS LIST ────────────────────────────────────
          // SliverList efficiently renders only the visible rows
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTimerRow(_timers[index]),
              childCount: _timers.length,
            ),
          ),

          // Bottom padding so the last card isn't flush with the nav bar
          const SliverToBoxAdapter(child: SizedBox(height: 32)),

        ],
      ),
    );
  }


  // --- SETTINGS WIDGETS ---

  Widget _buildWheels() {
    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(child: _wheel(_hoursCtrl,   24, 'h', (v) => setState(() => _h = v))),
          const Text(':', style: TextStyle(color: Colors.grey, fontSize: 28)),
          Expanded(child: _wheel(_minutesCtrl, 60, 'm', (v) => setState(() => _m = v))),
          const Text(':', style: TextStyle(color: Colors.grey, fontSize: 28)),
          Expanded(child: _wheel(_secondsCtrl, 60, 's', (v) => setState(() => _s = v))),
        ],
      ),
    );
  }

  Widget _wheel(FixedExtentScrollController ctrl, int count, String lbl,
      Function(int) onChanged) {
    return Column(
      children: [
        Text(lbl, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller:    ctrl,
            itemExtent:    48,
            perspective:   0.003,
            diameterRatio: 1.5,
            physics:       const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: count,
              builder: (context, index) {
                final bool sel = index == ctrl.selectedItem;
                return Center(
                  child: Text(
                    index.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color:      sel ? Colors.white : Colors.grey,
                      fontSize:   sel ? 28 : 20,
                      fontWeight: sel ? FontWeight.w400 : FontWeight.w300,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfig() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Label field
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.label_outline, color: Colors.grey),
              hintText:   'Label (optional)',
              hintStyle:  TextStyle(color: Colors.grey),
              border:     InputBorder.none,
            ),
            onChanged: (v) => setState(() => _label = v),
          ),
          const Divider(color: Color(0xFF3A3A3A)),
          // Ringtone picker
          Row(
            children: [
              const Icon(Icons.music_note_outlined, color: Colors.grey),
              const SizedBox(width: 12),
              const Text('Ringtone',
                  style: TextStyle(color: Colors.grey)),
              const Spacer(),
              DropdownButton<String>(
                value:         _ringtone,
                dropdownColor: const Color(0xFF2C2C2E),
                underline:     const SizedBox.shrink(),
                style:         const TextStyle(color: Colors.white),
                icon: const Icon(Icons.chevron_right, color: Colors.grey),
                onChanged: (v) => setState(() => _ringtone = v!),
                items: kRingtones
                    .map((r) =>
                        DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // --- TIMER ROW (Recent section) ---

  Widget _buildTimerRow(TimerEntry entry) {
    final Color ringColor = entry.state == TimerState.finished
        ? Colors.red
        : Color.lerp(Colors.red, Colors.orange, entry.progress)!;

    return Dismissible(
      key:       ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding:   const EdgeInsets.only(right: 20),
        color:     Colors.red,
        child:     const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTimer(entry),
      child: GestureDetector(
        onTap: () => setState(() => _expandedTimerId = entry.id),
        child: Container(
          margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:        const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(14),
            border: entry.state == TimerState.finished
                ? Border.all(color: Colors.orange, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.formattedRemaining,
                      style: TextStyle(
                        color: entry.state == TimerState.finished
                            ? Colors.orange : Colors.white,
                        fontSize:   40,
                        fontWeight: FontWeight.w200,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.label.isEmpty
                          ? entry.totalDurationLabel
                          : '${entry.totalDurationLabel} · ${entry.label}',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Play/pause ring button
              GestureDetector(
                onTap: () {
                  if (entry.state == TimerState.running) {
                    _pauseTimer(entry);
                  } else {
                    _resumeTimer(entry);
                  }
                },
                child: SizedBox(
                  width: 56, height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value:           entry.progress,
                        strokeWidth:     4,
                        backgroundColor: const Color(0xFF2C2C2E),
                        valueColor:      AlwaysStoppedAnimation<Color>(ringColor),
                      ),
                      Icon(
                        entry.state == TimerState.running
                            ? Icons.pause
                            : entry.state == TimerState.finished
                                ? Icons.check
                                : Icons.play_arrow,
                        color: ringColor,
                        size:  22,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// =========================================================================
// EXPANDED TIMER VIEW — full-screen detail when a row is tapped
// =========================================================================


class _ExpandedTimerView extends StatelessWidget {
  final TimerEntry   entry;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const _ExpandedTimerView({
    super.key,
    required this.entry,
    required this.onBack,
    required this.onCancel,
    required this.onPause,
    required this.onResume,
  });

  Color get _ringColor => entry.state == TimerState.finished
      ? Colors.red
      : Color.lerp(Colors.red, Colors.orange, entry.progress)!;

  @override
  Widget build(BuildContext context) {
    final double ringSize     = MediaQuery.of(context).size.width - 64;
    final double timeFontSize = ringSize / 5;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon:      const Icon(Icons.arrow_back_ios_new),
          onPressed: onBack,
        ),
        title: Text(entry.label.isEmpty ? 'Timer' : entry.label,
            style: const TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            SizedBox(
              width: ringSize, height: ringSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value:           entry.progress,
                      strokeWidth:     10,
                      backgroundColor: const Color(0xFF2C2C2E),
                      valueColor:      AlwaysStoppedAnimation<Color>(_ringColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.state == TimerState.running ||
                          entry.state == TimerState.paused)
                        Text('Ends at ${entry.endTimeLabel}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 15)),
                      if (entry.state == TimerState.finished)
                        const Text('Finished',
                            style: TextStyle(
                                color: Colors.orange, fontSize: 15)),
                      if (entry.state == TimerState.idle)
                        const Text('Ready',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(entry.formattedRemaining,
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   timeFontSize,
                            fontWeight: FontWeight.w200,
                            fontFamily: 'monospace',
                          )),
                      const SizedBox(height: 4),
                      Text(entry.totalDurationLabel,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CircleButton(
                  label:     'Cancel',
                  onPressed: entry.state == TimerState.idle ? null : onCancel,
                  color:     const Color(0xFF2C2C2E),
                ),
                if (entry.state == TimerState.running)
                  _CircleButton(
                    label: 'Pause', onPressed: onPause,
                    color: const Color(0xFF3A3A1A), labelColor: Colors.yellow,
                  ),
                if (entry.state == TimerState.paused)
                  _CircleButton(
                    label: 'Resume', onPressed: onResume,
                    color: const Color(0xFF1A3A1A), labelColor: Colors.green,
                  ),
                if (entry.state == TimerState.idle)
                  _CircleButton(
                    label: 'Start', onPressed: onResume,
                    color: const Color(0xFF1A3A1A), labelColor: Colors.green,
                  ),
                if (entry.state == TimerState.finished)
                  _CircleButton(
                    label: 'Restart', onPressed: onResume,
                    color: const Color(0xFF1A3A1A), labelColor: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.label_outline,
                      label: 'Label',
                      value: entry.label.isEmpty ? 'None' : entry.label),
                  const Divider(color: Color(0xFF3A3A3A), height: 24),
                  _InfoRow(icon: Icons.music_note_outlined,
                      label: 'Ringtone', value: entry.ringtone),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}


// =========================================================================
// SHARED WIDGETS
// =========================================================================


class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey,  fontSize: 14)),
        const Spacer(),
        Text(value,  style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }
}


class _CircleButton extends StatelessWidget {
  final String        label;
  final VoidCallback? onPressed;
  final Color         color;
  final Color         labelColor;

  const _CircleButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.labelColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: onPressed == null
              ? Colors.grey.withOpacity(0.2) : color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color:      onPressed == null ? Colors.grey : labelColor,
                fontSize:   16,
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }
}