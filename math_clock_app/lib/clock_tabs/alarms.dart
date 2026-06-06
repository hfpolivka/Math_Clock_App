import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


// =========================================================================
// ENUMS & CONSTANTS
// =========================================================================


enum Day { sun, mon, tue, wed, thu, fri, sat }

extension DayLabel on Day {
  String get label => switch (this) {
    Day.sun => 'Sun', Day.mon => 'Mon', Day.tue => 'Tue',
    Day.wed => 'Wed', Day.thu => 'Thu', Day.fri => 'Fri', Day.sat => 'Sat',
  };
}


enum MathDifficulty { veryEasy, easy, normal, hard, veryHard, superHard, hellMode }

extension MathDifficultyLabel on MathDifficulty {
  String get label => switch (this) {
    MathDifficulty.veryEasy  => 'Very Easy',
    MathDifficulty.easy      => 'Easy',
    MathDifficulty.normal    => 'Normal',
    MathDifficulty.hard      => 'Hard',
    MathDifficulty.veryHard  => 'Very Hard',
    MathDifficulty.superHard => 'Super Hard',
    MathDifficulty.hellMode  => 'Hell Mode',
  };
}


enum MathOperation { addition, subtraction, multiplication, division, decimals }

extension MathOperationLabel on MathOperation {
  String get label => switch (this) {
    MathOperation.addition       => 'Addition',
    MathOperation.subtraction    => 'Subtraction',
    MathOperation.multiplication => 'Multiplication',
    MathOperation.division       => 'Division',
    MathOperation.decimals       => 'Decimals / Fractions',
  };
}


const List<String> kSounds = [
  'Default', 'Chime', 'Bell', 'Digital', 'Marimba', 'Radar',
];


// =========================================================================
// DATA MODEL — Alarm
// =========================================================================


class Alarm {
  final String            id;
  int                     hour;
  int                     minute;
  Set<Day>                days;
  String                  label;
  String                  sound;
  bool                    snoozeEnabled;
  int                     mathCount;
  MathDifficulty          difficulty;
  Set<MathOperation>      operations;
  bool                    isEnabled;

  Alarm({
    required this.id,
    required this.hour,
    required this.minute,
    required this.days,
    required this.label,
    required this.sound,
    required this.snoozeEnabled,
    required this.mathCount,
    required this.difficulty,
    required this.operations,
    required this.isEnabled,
  });

  Map<String, dynamic> toJson() => {
    'id':            id,
    'hour':          hour,
    'minute':        minute,
    'days':          days.map((d) => d.index).toList(),
    'label':         label,
    'sound':         sound,
    'snoozeEnabled': snoozeEnabled,
    'mathCount':     mathCount,
    'difficulty':    difficulty.index,
    'operations':    operations.map((o) => o.index).toList(),
    'isEnabled':     isEnabled,
  };

  factory Alarm.fromJson(Map<String, dynamic> json) => Alarm(
    id:           json['id'],
    hour:         json['hour'],
    minute:       json['minute'],
    days:         (json['days'] as List)
                      .map((i) => Day.values[i as int])
                      .toSet(),
    label:        json['label'],
    sound:        json['sound'],
    snoozeEnabled: json['snoozeEnabled'],
    mathCount:    json['mathCount'],
    difficulty:   MathDifficulty.values[json['difficulty']],
    operations:   (json['operations'] as List)
                      .map((i) => MathOperation.values[i as int])
                      .toSet(),
    isEnabled:    json['isEnabled'],
  );

  String get formattedTime {
    final int h    = hour % 12 == 0 ? 12 : hour % 12;
    final String m = minute.toString().padLeft(2, '0');
    final String p = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  String get formattedDays {
    if (days.length == 7)  return 'Every day';
    if (days.isEmpty)      return 'Once';
    return Day.values
        .where((d) => days.contains(d))
        .map((d) => d.label)
        .join(', ');
  }
}


// =========================================================================
// MATH PROBLEM GENERATOR
// =========================================================================


class MathProblem {
  final String question;
  final num    answer;

  const MathProblem({required this.question, required this.answer});
}


MathProblem generateProblem(
  MathDifficulty difficulty,
  Set<MathOperation> operations,
) {
  final Random rng = Random();

  final List<MathOperation> ops = operations.isEmpty
      ? MathOperation.values
      : operations.toList();

  final MathOperation op = ops[rng.nextInt(ops.length)];

  int rand(int min, int max) => rng.nextInt(max - min + 1) + min;

  switch (difficulty) {

    case MathDifficulty.veryEasy:
      switch (op) {
        case MathOperation.addition:
          final a = rand(1, 9); final b = rand(1, 9);
          return MathProblem(question: '$a + $b = ?', answer: a + b);
        case MathOperation.subtraction:
          final a = rand(1, 9); final b = rand(1, a);
          return MathProblem(question: '$a - $b = ?', answer: a - b);
        case MathOperation.multiplication:
          final a = rand(1, 9); final b = rand(1, 9);
          return MathProblem(question: '$a × $b = ?', answer: a * b);
        case MathOperation.division:
          final b = rand(1, 9); final ans = rand(1, 9);
          return MathProblem(question: '${b * ans} ÷ $b = ?', answer: ans);
        case MathOperation.decimals:
          final a = rand(1, 5); final b = rand(1, 5);
          final ans = double.parse((a + b * 0.5).toStringAsFixed(2));
          return MathProblem(question: '$a + ${b * 0.5} = ?', answer: ans);
      }

    case MathDifficulty.easy:
      switch (op) {
        case MathOperation.addition:
          final a = rand(10, 50); final b = rand(1, 20);
          return MathProblem(question: '$a + $b = ?', answer: a + b);
        case MathOperation.subtraction:
          final a = rand(10, 50); final b = rand(1, a - 1);
          return MathProblem(question: '$a - $b = ?', answer: a - b);
        case MathOperation.multiplication:
          final a = rand(2, 12); final b = rand(2, 9);
          return MathProblem(question: '$a × $b = ?', answer: a * b);
        case MathOperation.division:
          final b = rand(2, 9); final ans = rand(2, 9);
          return MathProblem(question: '${b * ans} ÷ $b = ?', answer: ans);
        case MathOperation.decimals:
          final a = rand(10, 30); final b = rand(1, 9);
          final ans = double.parse((a + b * 0.1).toStringAsFixed(2));
          return MathProblem(
              question: '$a + ${(b * 0.1).toStringAsFixed(1)} = ?',
              answer:   ans);
      }

    case MathDifficulty.normal:
      switch (op) {
        case MathOperation.addition:
          final a = rand(10, 74); final b = rand(10, 25);
          return MathProblem(question: '$a + $b = ?', answer: a + b);
        case MathOperation.subtraction:
          final a = rand(20, 74); final b = rand(10, a - 1);
          return MathProblem(question: '$a - $b = ?', answer: a - b);
        case MathOperation.multiplication:
          final a = rand(10, 30); final b = rand(10, 55);
          return MathProblem(question: '$a × $b = ?', answer: a * b);
        case MathOperation.division:
          final b = rand(3, 12); final ans = rand(3, 12);
          return MathProblem(question: '${b * ans} ÷ $b = ?', answer: ans);
        case MathOperation.decimals:
          final a = rand(10, 50); final b = rand(10, 50);
          final ans = double.parse(((a + b) / 10.0).toStringAsFixed(2));
          return MathProblem(
              question: '($a + $b) ÷ 10 = ?',
              answer:   ans);
      }

    case MathDifficulty.hard:
      switch (op) {
        case MathOperation.addition:
          final a = rand(10, 50); final b = rand(10, 40); final c = rand(10, 34);
          return MathProblem(question: '$a + $b + $c = ?', answer: a + b + c);
        case MathOperation.subtraction:
          final a = rand(50, 99); final b = rand(10, 40); final c = rand(5, a - b - 1);
          return MathProblem(question: '$a - $b - $c = ?', answer: a - b - c);
        case MathOperation.multiplication:
          final a = rand(2, 9); final b = rand(2, 9); final c = rand(2, 8);
          return MathProblem(question: '$a × $b × $c = ?', answer: a * b * c);
        case MathOperation.division:
          final c = rand(2, 3); final b = rand(2, 9); final ans = rand(2, 9);
          return MathProblem(question: '${b * c * ans} ÷ $b ÷ $c = ?', answer: ans);
        case MathOperation.decimals:
          final a = rand(10, 50); final b = rand(5, 25);
          final ans = double.parse((a / b).toStringAsFixed(2));
          return MathProblem(
              question: '$a ÷ $b = ?',
              answer:   ans);
      }

    case MathDifficulty.veryHard:
      switch (op) {
        case MathOperation.addition:
        case MathOperation.multiplication:
          final a = rand(20, 72); final b = rand(2, 9); final c = rand(10, 99);
          return MathProblem(question: '($a × $b) + $c = ?', answer: (a * b) + c);
        case MathOperation.subtraction:
          final a = rand(20, 72); final b = rand(2, 9); final c = rand(10, 52);
          return MathProblem(question: '($a × $b) - $c = ?', answer: (a * b) - c);
        case MathOperation.division:
          final b = rand(2, 9); final ans = rand(10, 20); final c = rand(10, 67);
          return MathProblem(question: '(${b * ans} ÷ $b) + $c = ?', answer: ans + c);
        case MathOperation.decimals:
          final a = rand(10, 88); final b = rand(2, 4);
          final c = rand(5, 19);
          final ans = double.parse(((a / b) - c).toStringAsFixed(2));
          return MathProblem(
              question: '($a ÷ $b) - $c = ?',
              answer:   ans);
      }

    case MathDifficulty.superHard:
      switch (op) {
        case MathOperation.addition:
        case MathOperation.multiplication:
          final a = rand(20, 50); final b = rand(10, 15); final c = rand(100, 321);
          return MathProblem(question: '($a × $b) + $c = ?', answer: (a * b) + c);
        case MathOperation.subtraction:
          final a = rand(20, 50); final b = rand(10, 15); final c = rand(50, 200);
          return MathProblem(question: '($a × $b) - $c = ?', answer: (a * b) - c);
        case MathOperation.division:
          final b = rand(5, 18); final ans = rand(5, 15); final c = rand(50, 275);
          return MathProblem(question: '(${b * ans} ÷ $b) + $c = ?', answer: ans + c);
        case MathOperation.decimals:
          final a = rand(50, 100); final b = rand(5, 15); final c = rand(50, 194);
          final ans = double.parse(((a / b) - c).toStringAsFixed(2));
          return MathProblem(
              question: '($a ÷ $b) - $c = ?',
              answer:   ans);
      }

    case MathDifficulty.hellMode:
      switch (op) {
        case MathOperation.addition:
        case MathOperation.multiplication:
          final a = rand(100, 213); final b = rand(30, 87); final c = rand(500, 1878);
          return MathProblem(question: '($a × $b) + $c = ?', answer: (a * b) + c);
        case MathOperation.subtraction:
          final a = rand(100, 344); final b = rand(30, 65); final c = rand(500, 2951);
          return MathProblem(question: '($a × $b) - $c = ?', answer: (a * b) - c);
        case MathOperation.division:
          final b = rand(10, 42); final ans = rand(10, 30); final c = rand(500, 1530);
          return MathProblem(question: '(${b * ans} ÷ $b) + $c = ?', answer: ans + c);
        case MathOperation.decimals:
          final a = rand(100, 344); final b = rand(10, 42); final c = rand(500, 2951);
          final ans = double.parse(((a / b) - c).toStringAsFixed(2));
          return MathProblem(
              question: '($a ÷ $b) - $c = ?',
              answer:   ans);
      }
  }
}


// =========================================================================
// ALARMS TAB
// =========================================================================


// AlarmsTabState is public (no leading underscore) so HomeScreen can hold
// a GlobalKey<AlarmsTabState> and call checkAlarms() from outside.
class AlarmsTab extends StatefulWidget {
  const AlarmsTab({super.key});

  @override
  State<AlarmsTab> createState() => AlarmsTabState();
}


class AlarmsTabState extends State<AlarmsTab> {

  List<Alarm>   _alarms    = [];
  _MathSession? _activeMath;
  bool          _isLoading = true;


  // --- LIFECYCLE ---

  @override
  void initState() {
    super.initState();
    _loadAlarms();
  }


  // --- PERSISTENCE ---

  Future<void> _loadAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? raw       = prefs.getStringList('alarms');
    if (raw != null) {
      setState(() {
        _alarms = raw
            .map((s) => Alarm.fromJson(jsonDecode(s)))
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveAlarms() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> raw        = _alarms
        .map((a) => jsonEncode(a.toJson()))
        .toList();
    await prefs.setStringList('alarms', raw);
  }


  // Tracks the last minute an alarm fired, keyed by alarm ID.
  // Format: "$hour:$minute" — e.g. "7:30"
  //
  // WHY this is needed:
  //   checkAlarms() is called every 30 seconds from HomeScreen.
  //   That means it fires twice in the same clock-minute (e.g. at 7:30:00
  //   and again at 7:30:30). Both calls see hour==7 and minute==30, so
  //   _fireAlarm() would be called twice, opening two math screens on top
  //   of each other. Storing the last-fired minute per alarm prevents the
  //   second call from doing anything.
  final Map<String, String> _lastFiredMinute = {};

  // --- PUBLIC: called by HomeScreen's periodic timer ---

  void checkAlarms() {
    final DateTime now    = DateTime.now();
    final String   nowKey = '${now.hour}:${now.minute}';

    for (final Alarm alarm in _alarms) {
      if (!alarm.isEnabled) continue;
      if (alarm.hour != now.hour || alarm.minute != now.minute) continue;

      // Only fire once per minute for this alarm
      if (_lastFiredMinute[alarm.id] == nowKey) continue;

      _lastFiredMinute[alarm.id] = nowKey;
      _fireAlarm(alarm);
    }
  }


  // --- ACTIONS ---

  void _openAddSheet({Alarm? existing}) async {
    await showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _AlarmSheet(
        existing: existing,
        onSave: (Alarm alarm) async {
          setState(() {
            if (existing != null) {
              final int idx = _alarms.indexWhere((a) => a.id == alarm.id);
              if (idx != -1) _alarms[idx] = alarm;
            } else {
              _alarms.add(alarm);
            }
          });
          await _saveAlarms();
        },
      ),
    );
  }

  void _toggleAlarm(int index, bool value) async {
    setState(() => _alarms[index].isEnabled = value);
    await _saveAlarms();
  }

  void _deleteAlarm(int index) async {
    setState(() => _alarms.removeAt(index));
    await _saveAlarms();
  }

  void _fireAlarm(Alarm alarm) {
    setState(() {
      _activeMath = _MathSession(alarm: alarm);
    });
  }

  void _dismissMath() {
    setState(() => _activeMath = null);
  }


  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body:            Center(child: CircularProgressIndicator()),
      );
    }

    return Stack(
      children: [
        _buildAlarmList(),
        if (_activeMath != null)
          _MathScreen(
            session:   _activeMath!,
            onDismiss: _dismissMath,
          ),
      ],
    );
  }


  Widget _buildAlarmList() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:           const Text('Alarms'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon:      const Icon(Icons.add),
            onPressed: () => _openAddSheet(),
          ),
        ],
      ),
      body: _alarms.isEmpty
          ? const Center(
              child: Text(
                'No alarms set.\nTap + to add one.',
                textAlign: TextAlign.center,
                style:     TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.builder(
              physics:   const ClampingScrollPhysics(),
              itemCount: _alarms.length,
              itemBuilder: (context, index) {
                final Alarm alarm = _alarms[index];
                return Dismissible(
                  key:       ValueKey(alarm.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding:   const EdgeInsets.only(right: 20),
                    color:     Colors.red,
                    child:     const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _deleteAlarm(index),
                  child: GestureDetector(
                    onTap: () => _openAddSheet(existing: alarm),
                    child: _buildAlarmCard(alarm, index),
                  ),
                );
              },
            ),
    );
  }


  Widget _buildAlarmCard(Alarm alarm, int index) {
    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color:        const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (alarm.label.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      alarm.label,
                      style: TextStyle(
                        color:    alarm.isEnabled ? Colors.white70 : Colors.grey,
                        fontSize: 15,
                      ),
                    ),
                  ),
                Text(
                  alarm.formattedTime,
                  style: TextStyle(
                    color:      alarm.isEnabled ? Colors.white : Colors.grey,
                    fontSize:   38,
                    fontWeight: FontWeight.w200,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alarm.formattedDays,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                // Simulate button — handy for testing without waiting
                TextButton(
                  onPressed: () => _fireAlarm(alarm),
                  style: TextButton.styleFrom(
                    padding:       EdgeInsets.zero,
                    minimumSize:   Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Simulate alarm',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value:       alarm.isEnabled,
            onChanged:   (v) => _toggleAlarm(index, v),
            activeColor: Colors.orange,
          ),

        ],
      ),
    );
  }
}


// =========================================================================
// ALARM SHEET — Add / Edit
// =========================================================================


class _AlarmSheet extends StatefulWidget {
  final Alarm?          existing;
  final Function(Alarm) onSave;

  const _AlarmSheet({required this.onSave, this.existing});

  @override
  State<_AlarmSheet> createState() => _AlarmSheetState();
}


class _AlarmSheetState extends State<_AlarmSheet> {

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  static const int _loopMultiplier = 10000;

  late int                _hour;
  late int                _minute;
  late Set<Day>           _days;
  late String             _label;
  late String             _sound;
  late bool               _snooze;
  late int                _mathCount;
  late MathDifficulty     _difficulty;
  late Set<MathOperation> _operations;

  MathProblem? _previewProblem;


  @override
  void initState() {
    super.initState();
    final Alarm? e = widget.existing;

    _hour       = e?.hour       ?? TimeOfDay.now().hour;
    _minute     = e?.minute     ?? TimeOfDay.now().minute;
    _days       = e?.days       ?? {Day.mon, Day.tue, Day.wed, Day.thu, Day.fri};
    _label      = e?.label      ?? '';
    _sound      = e?.sound      ?? kSounds.first;
    _snooze     = e?.snoozeEnabled ?? true;
    _mathCount  = e?.mathCount  ?? 1;
    _difficulty = e?.difficulty ?? MathDifficulty.easy;
    _operations = e?.operations ?? {MathOperation.addition};

    _hourController   = FixedExtentScrollController(
      initialItem: _loopMultiplier * 24 + _hour,
    );
    _minuteController = FixedExtentScrollController(
      initialItem: _loopMultiplier * 60 + _minute,
    );

    _refreshPreview();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _refreshPreview() {
    setState(() {
      _previewProblem = generateProblem(_difficulty, _operations);
    });
  }

  void _save() {
    final Alarm alarm = Alarm(
      id:           widget.existing?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
      hour:         _hour,
      minute:       _minute,
      days:         Set.from(_days),
      label:        _label,
      sound:        _sound,
      snoozeEnabled: _snooze,
      mathCount:    _mathCount,
      difficulty:   _difficulty,
      operations:   Set.from(_operations),
      isEnabled:    widget.existing?.isEnabled ?? true,
    );
    widget.onSave(alarm);
    Navigator.of(context).pop();
  }


  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand:           false,
      initialChildSize: 0.92,
      minChildSize:     0.5,
      maxChildSize:     0.97,
      builder: (context, scrollController) {
        return Column(
          children: [

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  TextButton(
                    onPressed: _save,
                    child: const Text('Save',
                        style: TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollController,
                padding:    const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTimeWheels(),
                  const SizedBox(height: 24),
                  _buildSection('Repeat',  _buildRepeat()),
                  _buildSection('Label',   _buildLabel()),
                  _buildSection('Sound',   _buildSound()),
                  _buildSection('Snooze',  _buildSnooze()),
                  _buildSection('Math',    _buildMath()),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildSection(String title, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, letterSpacing: 0.8)),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }


  Widget _buildTimeWheels() {
    return SizedBox(
      height: 160,
      child: Row(
        children: [

          Expanded(
            child: _buildInfiniteWheel(
              controller: _hourController,
              itemCount:  24,
              onChanged:  (i) => setState(() => _hour = i % 24),
              label:      'Hour',
            ),
          ),

          const Text(':', style: TextStyle(color: Colors.white, fontSize: 36)),

          Expanded(
            child: _buildInfiniteWheel(
              controller: _minuteController,
              itemCount:  60,
              onChanged:  (i) => setState(() => _minute = i % 60),
              label:      'Min',
            ),
          ),

        ],
      ),
    );
  }


  Widget _buildInfiniteWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required Function(int) onChanged,
    required String label,
  }) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller:    controller,
            itemExtent:    52,
            perspective:   0.003,
            diameterRatio: 1.4,
            physics:       const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onChanged,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount * _loopMultiplier * 2,
              builder: (context, index) {
                final int  value      = index % itemCount;
                final bool isSelected = index == controller.selectedItem;
                return Center(
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: TextStyle(
                      color:      isSelected ? Colors.white : Colors.grey,
                      fontSize:   isSelected ? 32 : 22,
                      fontWeight: isSelected ? FontWeight.w400 : FontWeight.w300,
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


  Widget _buildRepeat() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: Day.values.map((day) {
        final bool selected = _days.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            selected ? _days.remove(day) : _days.add(day);
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color:        selected ? Colors.orange : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              day.label,
              style: TextStyle(
                color:      selected ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500,
                fontSize:   13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildLabel() {
    return TextField(
      controller: TextEditingController(text: _label)
        ..selection = TextSelection.collapsed(offset: _label.length),
      style:     const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText:  'e.g. Work, Gym...',
        hintStyle: TextStyle(color: Colors.grey),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.orange)),
      ),
      onChanged: (v) => _label = v,
    );
  }


  Widget _buildSound() {
    return DropdownButton<String>(
      value:         _sound,
      dropdownColor: const Color(0xFF2C2C2E),
      isExpanded:    true,
      underline:     const Divider(color: Colors.grey),
      style:         const TextStyle(color: Colors.white),
      icon:          const Icon(Icons.chevron_right, color: Colors.grey),
      onChanged:     (v) => setState(() => _sound = v!),
      items: kSounds
          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
          .toList(),
    );
  }


  Widget _buildSnooze() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Enable snooze',
            style: TextStyle(color: Colors.white, fontSize: 15)),
        Switch(
          value:       _snooze,
          onChanged:   (v) => setState(() => _snooze = v),
          activeColor: Colors.orange,
        ),
      ],
    );
  }


  Widget _buildMath() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text('Problems to solve',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [1, 2, 3].map((count) {
            final bool selected = _mathCount == count;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _mathCount = count),
                child: Container(
                  width:  56,
                  height: 44,
                  decoration: BoxDecoration(
                    color:        selected ? Colors.orange : const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'x$count',
                      style: TextStyle(
                        color:      selected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize:   16,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        const Text('Preview',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _refreshPreview,
          child: Container(
            width:   double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:        const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Text(
                  _previewProblem?.question ?? '...',
                  style: const TextStyle(
                    color:      Colors.white,
                    fontSize:   22,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                const Text('tap to refresh',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text('Operations',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),
        ...MathOperation.values.map((op) {
          final bool checked = _operations.contains(op);
          return CheckboxListTile(
            value:           checked,
            title: Text(op.label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            activeColor:     Colors.orange,
            checkColor:      Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding:  EdgeInsets.zero,
            dense:           true,
            onChanged: (v) {
              setState(() {
                v! ? _operations.add(op) : _operations.remove(op);
                if (_operations.isEmpty) _operations.add(op);
              });
              _refreshPreview();
            },
          );
        }),

        const SizedBox(height: 16),

        const Text('Difficulty',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Very Easy',
                style: TextStyle(color: Colors.grey, fontSize: 11)),
            const Text('Hell Mode',
                style: TextStyle(color: Colors.red, fontSize: 11)),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            showValueIndicator:  ShowValueIndicator.never,
            activeTrackColor:    Colors.orange,
            inactiveTrackColor:  const Color(0xFF2C2C2E),
            thumbColor:          Colors.orange,
            overlayColor:        Colors.orange.withOpacity(0.2),
          ),
          child: Slider(
            min:       0,
            max:       6,
            divisions: 6,
            value:     _difficulty.index.toDouble(),
            onChanged: (v) {
              setState(() => _difficulty = MathDifficulty.values[v.round()]);
              _refreshPreview();
            },
          ),
        ),
        Center(
          child: Text(
            _difficulty.label,
            style: TextStyle(
              color:      _difficulty == MathDifficulty.hellMode
                  ? Colors.red
                  : Colors.orange,
              fontSize:   13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

      ],
    );
  }
}


// =========================================================================
// MATH SESSION — tracks state for the firing alarm
// =========================================================================


class _MathSession {
  final Alarm alarm;

  // Total problems the user must solve before the alarm dismisses
  final int totalProblems;

  // How many have been correctly solved so far
  int problemsSolved = 0;

  // The problem currently on screen — set once and never changed until
  // the user answers correctly. This is important: we must NOT generate
  // a new problem until the current one is answered, so the answer
  // the user types can always be compared to the same question.
  MathProblem currentProblem;

  _MathSession({required this.alarm})
      : totalProblems  = alarm.mathCount,
        // Generate the very first problem immediately
        currentProblem = generateProblem(alarm.difficulty, alarm.operations);

  // How many problems are left (drives the progress label)
  int get problemsRemaining => totalProblems - problemsSolved;

  // Check whether the typed answer matches the current problem.
  //
  // Returns true  → answer is CORRECT
  // Returns false → answer is WRONG (same problem stays on screen)
  //
  // IMPORTANT: this method no longer advances to the next problem.
  // Advancing is done in _MathScreenState._submit() AFTER setState()
  // so the widget always shows the right question text.
  bool checkAnswer(String input) {
    final num? entered = num.tryParse(input.trim());
    if (entered == null) return false;

    // Allow ±0.05 tolerance for floating-point decimal answers
    return (entered - currentProblem.answer).abs() < 0.05;
  }

  // Called by _MathScreenState after a correct answer has been rendered.
  // Increments the counter and generates the next problem.
  // Returns true when all problems are done (alarm should dismiss).
  bool advance() {
    problemsSolved++;
    if (problemsRemaining > 0) {
      currentProblem = generateProblem(alarm.difficulty, alarm.operations);
    }
    return problemsRemaining == 0;
  }
}


// =========================================================================
// MATH SCREEN — full-screen overlay shown when an alarm fires
// =========================================================================


class _MathScreen extends StatefulWidget {
  final _MathSession session;
  final VoidCallback onDismiss;

  const _MathScreen({required this.session, required this.onDismiss});

  @override
  State<_MathScreen> createState() => _MathScreenState();
}


class _MathScreenState extends State<_MathScreen> {

  final TextEditingController _inputCtrl = TextEditingController();

  // true  → show the red "Incorrect — try again" error
  // false → normal state
  bool _showError = false;

  // true → the user just answered correctly; show brief green feedback
  // before advancing to the next problem (or dismissing)
  bool _showCorrect = false;


  @override
  void dispose() {
    _inputCtrl.dispose();
    super.dispose();
  }


  void _submit() {
    // Don't accept new input while showing the "Correct!" flash
    if (_showCorrect) return;

    final bool correct = widget.session.checkAnswer(_inputCtrl.text);

    if (correct) {
      // 1. Show green "Correct!" flash so the user gets clear feedback
      setState(() {
        _showError   = false;
        _showCorrect = true;
        _inputCtrl.clear();
      });

      // 2. After a short delay, advance the session and either move to
      //    the next problem or dismiss the alarm entirely.
      //    Doing this in a delayed callback means the widget rebuilds
      //    with the NEW problem only after the green flash is visible —
      //    so checkAnswer() was never called against a stale question.
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        final bool done = widget.session.advance();
        if (done) {
          widget.onDismiss();
        } else {
          setState(() => _showCorrect = false);
        }
      });

    } else {
      // Wrong answer — stay on the same problem, show error
      setState(() {
        _showError = true;
        _inputCtrl.clear();
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final _MathSession session = widget.session;

    // Border colour reflects current state
    final Color borderColor = _showCorrect
        ? Colors.green
        : _showError
            ? Colors.red
            : Colors.grey;

    final Color focusedBorderColor = _showCorrect
        ? Colors.green
        : _showError
            ? Colors.red
            : Colors.orange;

    return Container(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              if (session.alarm.label.isNotEmpty)
                Text(
                  session.alarm.label,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),

              const SizedBox(height: 8),

              const Text(
                'Solve to dismiss',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 8),

              // "Problem X of Y" progress label
              Text(
                'Problem ${session.problemsSolved + 1} of ${session.totalProblems}',
                style: const TextStyle(color: Colors.orange, fontSize: 13),
              ),

              const SizedBox(height: 32),

              // The math question — reads from session.currentProblem which
              // only changes after advance() is called, never mid-attempt
              Text(
                session.currentProblem.question,
                style: const TextStyle(
                  color:      Colors.white,
                  fontSize:   42,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),

              const SizedBox(height: 8),

              // Correct! feedback line — green, appears for 600 ms
              if (_showCorrect)
                const Text(
                  '✓ Correct!',
                  style: TextStyle(
                    color:      Colors.green,
                    fontSize:   18,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                const SizedBox(height: 22),

              const SizedBox(height: 16),

              // Answer input
              TextField(
                controller:   _inputCtrl,
                autofocus:    true,
                // numberWithOptions(decimal: true) shows a numeric keyboard
                // that also has a decimal point key
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign:    TextAlign.center,
                style:        const TextStyle(color: Colors.white, fontSize: 28),
                decoration: InputDecoration(
                  hintText:  '?',
                  hintStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: focusedBorderColor),
                  ),
                  errorText: _showError ? 'Incorrect — try again' : null,
                ),
                onChanged:   (_) => setState(() => _showError = false),
                onSubmitted: (_) => _submit(),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showCorrect ? Colors.green : Colors.orange,
                    padding:         const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(
                      color:      Colors.black,
                      fontSize:   18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              if (session.alarm.snoozeEnabled) ...[
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:         Text('Snoozed for 9 minutes'),
                        backgroundColor: Color(0xFF2C2C2E),
                      ),
                    );
                    widget.onDismiss();
                  },
                  child: const Text(
                    'Snooze (9 min)',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],

            ],
          ),
        ),
      ),
    );
  }
}