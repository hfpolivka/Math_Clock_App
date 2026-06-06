import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';


// =========================================================================
// DATA MODEL
// =========================================================================


class LapEntry {
  final int      lapNumber;
  final Duration lapTime;
  final Duration totalTime;

  const LapEntry({
    required this.lapNumber,
    required this.lapTime,
    required this.totalTime,
  });
}


// =========================================================================
// STOPWATCH TAB
// =========================================================================


class StopwatchTab extends StatefulWidget {
  const StopwatchTab({super.key});

  @override
  State<StopwatchTab> createState() => _StopwatchTabState();
}


class _StopwatchTabState extends State<StopwatchTab>
    with AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final Stopwatch      _stopwatch    = Stopwatch();
  Timer?               _ticker;
  final List<LapEntry> _laps         = [];
  Duration             _lastLapTime  = Duration.zero;

  // Elapsed time from a previous session. Added to _stopwatch.elapsed
  // to get the true total elapsed time across sessions.
  Duration             _savedElapsed = Duration.zero;

  // Wall-clock time the stopwatch was last started.
  // Used to recalculate elapsed correctly if the app was killed while running.
  DateTime?            _startedAt;


  // --- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }


  // --- PERSISTENCE ---

  Future<void> _saveState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      'stopwatch_laps',
      _laps.map((l) =>
          '${l.lapNumber}|${l.lapTime.inMilliseconds}|${l.totalTime.inMilliseconds}'
      ).toList(),
    );

    // Save total elapsed at this moment
    await prefs.setInt('stopwatch_elapsed', _elapsed.inMilliseconds);

    // Save the wall-clock start time if running so we can recover
    // the time elapsed while the app was closed
    if (_stopwatch.isRunning && _startedAt != null) {
      await prefs.setInt(
          'stopwatch_started_at', _startedAt!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('stopwatch_started_at');
    }
  }

  Future<void> _loadState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Recover elapsed time. If the stopwatch was running when the app
    // closed, calculate additional time from the saved start timestamp.
    final int? savedMs    = prefs.getInt('stopwatch_elapsed');
    final int? startedAt  = prefs.getInt('stopwatch_started_at');

    int totalMs = savedMs ?? 0;
    if (startedAt != null) {
      // App was killed while running — add the time that passed
      final int additionalMs =
          DateTime.now().millisecondsSinceEpoch - startedAt;
      totalMs += additionalMs;
    }

    // Restore laps
    final List<String>? encoded = prefs.getStringList('stopwatch_laps');
    if (encoded != null && encoded.isNotEmpty) {
      final List<LapEntry> laps = encoded.map((s) {
        final List<String> p = s.split('|');
        return LapEntry(
          lapNumber: int.parse(p[0]),
          lapTime:   Duration(milliseconds: int.parse(p[1])),
          totalTime: Duration(milliseconds: int.parse(p[2])),
        );
      }).toList();

      setState(() {
        _laps.addAll(laps);
        _lastLapTime = laps.isNotEmpty ? laps.first.totalTime : Duration.zero;
      });
    }

    if (totalMs > 0) {
      setState(() => _savedElapsed = Duration(milliseconds: totalMs));
    }
  }


  // --- DERIVED ---

  Duration get _elapsed => _stopwatch.elapsed + _savedElapsed;
  bool     get _isRunning => _stopwatch.isRunning;


  // --- ACTIONS ---

  void _start() {
    _startedAt = DateTime.now();
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), (_) {
      setState(() {});
    });
    _saveState();
  }

  void _stop() {
    _stopwatch.stop();
    _ticker?.cancel();
    _ticker    = null;
    _startedAt = null;
    setState(() {});
    _saveState();
  }

  void _reset() {
    _stopwatch.reset();
    _ticker?.cancel();
    _ticker = null;
    setState(() {
      _laps.clear();
      _lastLapTime  = Duration.zero;
      _savedElapsed = Duration.zero;
      _startedAt    = null;
    });
    _saveState();
  }

  void _lap() {
    final Duration total   = _elapsed;
    final Duration lapTime = total - _lastLapTime;
    setState(() {
      _laps.insert(0, LapEntry(
        lapNumber: _laps.length + 1,
        lapTime:   lapTime,
        totalTime: total,
      ));
      _lastLapTime = total;
    });
    _saveState();
  }


  // --- HELPERS ---

  String _formatDuration(Duration d) {
    final int m  = d.inMinutes;
    final int s  = d.inSeconds % 60;
    final int cs = (d.inMilliseconds % 1000) ~/ 10;
    return '${_pad(m)}:${_pad(s)}.${_pad(cs)}';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');


  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Duration elapsed     = _elapsed;
    final double   screenWidth = MediaQuery.of(context).size.width;
    final double   dialSize    = screenWidth - 48;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Stopwatch', style: TextStyle(
          color: Colors.orange,
        )),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [

          const SizedBox(height: 16),

          SizedBox(
            width:  dialSize,
            height: dialSize,
            child: CustomPaint(
              painter: _StopwatchDialPainter(elapsed: elapsed),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: dialSize * 0.32),
                    Text(
                      _formatDuration(elapsed),
                      style: TextStyle(
                        color:      Colors.white70,
                        fontSize:   dialSize * 0.065,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(
                  label:     _isRunning ? 'Lap' : 'Reset',
                  onPressed: _isRunning
                      ? _lap
                      : (elapsed == Duration.zero ? null : _reset),
                  color:     const Color(0xFF2C2C2E),
                ),
                _CircleButton(
                  label:      _isRunning ? 'Stop' : 'Start',
                  onPressed:  _isRunning ? _stop : _start,
                  color:      _isRunning
                      ? const Color(0xFF3A1A1A)
                      : const Color(0xFF1A3A1A),
                  labelColor: _isRunning ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: Color(0xFF2C2C2E), height: 1),

          Expanded(
            child: _laps.isEmpty
                ? const Center(
                    child: Text('No laps recorded.',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  )
                : ListView.builder(
                    physics:   const ClampingScrollPhysics(),
                    itemCount: _laps.length,
                    itemBuilder: (context, index) {
                      final LapEntry lap          = _laps[index];
                      final bool     isMostRecent = index == 0;

                      Duration? shortest;
                      Duration? longest;
                      if (_laps.length >= 2) {
                        shortest = _laps.map((l) => l.lapTime)
                            .reduce((a, b) => a < b ? a : b);
                        longest  = _laps.map((l) => l.lapTime)
                            .reduce((a, b) => a > b ? a : b);
                      }

                      Color rowColor = Colors.white;
                      if (isMostRecent)                rowColor = Colors.orange;
                      else if (lap.lapTime == shortest) rowColor = Colors.green;
                      else if (lap.lapTime == longest)  rowColor = Colors.red;

                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Lap ${lap.lapNumber}',
                                    style: TextStyle(
                                        color: rowColor, fontSize: 15)),
                                Text(_formatDuration(lap.lapTime),
                                    style: TextStyle(
                                        color:      rowColor,
                                        fontSize:   15,
                                        fontFamily: 'monospace')),
                              ],
                            ),
                          ),
                          const Divider(
                            color:      Color(0xFF2C2C2E),
                            height:     1,
                            indent:     32,
                            endIndent:  32,
                          ),
                        ],
                      );
                    },
                  ),
          ),

        ],
      ),
    );
  }
}


// =========================================================================
// ANALOG DIAL PAINTER
// =========================================================================


class _StopwatchDialPainter extends CustomPainter {

  final Duration elapsed;
  _StopwatchDialPainter({required this.elapsed});

  @override
  bool shouldRepaint(_StopwatchDialPainter old) => old.elapsed != elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = Offset(size.width / 2, size.height / 2);
    final double radius = size.width / 2;
    _drawBezel(canvas, centre, radius);
    _drawFace(canvas, centre, radius);
    _drawTickMarks(canvas, centre, radius);
    _drawNumbers(canvas, centre, radius);
    _drawSubDial(canvas, centre, radius);
    _drawMinuteHand(canvas, centre, radius);
    _drawSecondHand(canvas, centre, radius);
    _drawHub(canvas, centre);
  }

  void _drawBezel(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(centre, radius,
        Paint()..color = const Color(0xFF3A3A3C));
  }

  void _drawFace(Canvas canvas, Offset centre, double radius) {
    canvas.drawCircle(centre, radius - 8,
        Paint()
          ..shader = RadialGradient(
            colors: [const Color(0xFF2C2C2E), const Color(0xFF111111)],
          ).createShader(
            Rect.fromCircle(center: centre, radius: radius - 8)));
  }

  void _drawTickMarks(Canvas canvas, Offset centre, double radius) {
    final double faceEdge = radius - 10;
    for (int i = 0; i < 60; i++) {
      final bool   isMajor    = i % 5 == 0;
      final double tickLength = isMajor ? radius * 0.10 : radius * 0.05;
      final double angle      = (i / 60) * 2 * pi - pi / 2;
      canvas.drawLine(
        Offset(centre.dx + faceEdge * cos(angle),
               centre.dy + faceEdge * sin(angle)),
        Offset(centre.dx + (faceEdge - tickLength) * cos(angle),
               centre.dy + (faceEdge - tickLength) * sin(angle)),
        Paint()
          ..color       = isMajor ? Colors.white : Colors.white30
          ..strokeWidth = isMajor ? 2.5 : 1.2
          ..strokeCap   = StrokeCap.round,
      );
    }
  }

  void _drawNumbers(Canvas canvas, Offset centre, double radius) {
    for (int i = 0; i < 12; i++) {
      final double angle = (i / 12) * 2 * pi - pi / 2;
      final Offset pos   = Offset(
        centre.dx + radius * 0.72 * cos(angle),
        centre.dy + radius * 0.72 * sin(angle),
      );
      final TextPainter tp = TextPainter(
        text: TextSpan(
          text:  '${i * 5}',
          style: TextStyle(
              color:      Colors.white60,
              fontSize:   radius * 0.095,
              fontWeight: FontWeight.w300),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _drawSubDial(Canvas canvas, Offset centre, double radius) {
    final double subR = radius * 0.20;
    final Offset sub  = Offset(centre.dx, centre.dy - radius * 0.40);

    canvas.drawCircle(sub, subR, Paint()..color = const Color(0xFF1A1A1A));
    canvas.drawCircle(sub, subR,
        Paint()
          ..color       = Colors.white24
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.0);

    for (int i = 0; i < 30; i++) {
      final bool   isMajor = i % 5 == 0;
      final double angle   = (i / 30) * 2 * pi - pi / 2;
      final double len     = isMajor ? subR * 0.28 : subR * 0.16;
      canvas.drawLine(
        Offset(sub.dx + subR * cos(angle), sub.dy + subR * sin(angle)),
        Offset(sub.dx + (subR - len) * cos(angle),
               sub.dy + (subR - len) * sin(angle)),
        Paint()
          ..color       = isMajor ? Colors.white54 : Colors.white24
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    final double fraction =
        (elapsed.inMinutes % 30) / 30 +
        (elapsed.inSeconds % 60) / (30 * 60);
    final double angle = fraction * 2 * pi - pi / 2;
    canvas.drawLine(
      sub,
      Offset(sub.dx + subR * 0.65 * cos(angle),
             sub.dy + subR * 0.65 * sin(angle)),
      Paint()..color = Colors.white..strokeWidth = 1.5..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(sub, subR * 0.10, Paint()..color = Colors.white70);
  }

  void _drawMinuteHand(Canvas canvas, Offset centre, double radius) {
    final double fraction = (elapsed.inMilliseconds % 60000) / 60000;
    final double angle    = fraction * 2 * pi - pi / 2;
    canvas.drawLine(
      Offset(centre.dx - radius * 0.12 * cos(angle),
             centre.dy - radius * 0.12 * sin(angle)),
      Offset(centre.dx + radius * 0.52 * cos(angle),
             centre.dy + radius * 0.52 * sin(angle)),
      Paint()..color = Colors.white..strokeWidth = 3.5..strokeCap = StrokeCap.round,
    );
  }

  void _drawSecondHand(Canvas canvas, Offset centre, double radius) {
    final double fraction = (elapsed.inMilliseconds % 1000) / 1000;
    final double angle    = fraction * 2 * pi - pi / 2;
    final Offset tip  = Offset(centre.dx + radius * 0.70 * cos(angle),
                               centre.dy + radius * 0.70 * sin(angle));
    final Offset tail = Offset(centre.dx - radius * 0.18 * cos(angle),
                               centre.dy - radius * 0.18 * sin(angle));
    canvas.drawLine(centre, tail,
        Paint()..color = Colors.orange..strokeWidth = 3..strokeCap = StrokeCap.round);
    canvas.drawLine(centre, tip,
        Paint()..color = Colors.orange..strokeWidth = 1.5..strokeCap = StrokeCap.round);
  }

  void _drawHub(Canvas canvas, Offset centre) {
    canvas.drawCircle(centre, 7, Paint()..color = Colors.orange);
    canvas.drawCircle(centre, 3, Paint()..color = const Color(0xFF1C1C1E));
  }
}


// =========================================================================
// CIRCLE BUTTON
// =========================================================================


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
        width:  88,
        height: 88,
        decoration: BoxDecoration(
          color:  onPressed == null
              ? Colors.grey.withOpacity(0.2) : color,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                color:      onPressed == null ? Colors.grey : labelColor,
                fontSize:   17,
                fontWeight: FontWeight.w500,
              )),
        ),
      ),
    );
  }
}