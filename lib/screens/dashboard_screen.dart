import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';
import 'nutrition_meals_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _selectedNavIndex = 1; // Calendar is default/middle

  // Cycle data loaded from SharedPreferences
  late DateTime _lastPeriodStart;
  late int _cycleLength;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _loadCycleData() async {
    final prefs = await SharedPreferences.getInstance();

    String? lastPeriodStr = prefs.getString('lastPeriodStart');
    _lastPeriodStart = lastPeriodStr != null
        ? DateTime.parse(lastPeriodStr)
        : DateTime(2024, 11, 28);

    _cycleLength = prefs.getInt('cycleLength') ?? 28;

    setState(() {
      _isLoading = false;
    });
  }

  int _getCurrentCycleDay() {
    int daysSinceStart = DateTime.now().difference(_lastPeriodStart).inDays;
    return (daysSinceStart % _cycleLength) + 1;
  }

  String _getCurrentPhase() {
    return getCyclePhase(_lastPeriodStart, _cycleLength, DateTime.now());
  }

  String _getCyclePhase(DateTime day) {
    return getCyclePhase(_lastPeriodStart, _cycleLength, day);
  }

  int _getOvulationDay() {
    return (_cycleLength ~/ 2);
  }

  Color _getPhaseColor(String phase) {
    return getPhaseColor(phase);
  }

  void _showDayDetails(DateTime day) {
    String phase = _getCyclePhase(day);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailsModal(
        date: day,
        phase: phase,
        lastPeriodStart: _lastPeriodStart,
        cycleLength: _cycleLength,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GradientWrapper(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            // Fixed Header - Full Square, No Rounded Corners
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              color: Colors.grey.shade200,
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day ${_getCurrentCycleDay()} • ${getPhaseEmoji(_getCurrentPhase())} ${_getCurrentPhase()} phase',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getPhaseExtension(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Calendar in Middle - Scrollable for Month Navigation
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      leftChevronIcon: const Icon(
                        Icons.chevron_left,
                        color: Color(0xFF333333),
                      ),
                      rightChevronIcon: const Icon(
                        Icons.chevron_right,
                        color: Color(0xFF333333),
                      ),
                    ),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      _showDayDetails(selectedDay);
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, day, focusedDay) {
                        String phase = _getCyclePhase(day);
                        bool isToday = isSameDay(day, DateTime.now());
                        int dayInCycle =
                            ((day.difference(_lastPeriodStart).inDays %
                                    _cycleLength) +
                                1);
                        int ovulationDay = _getOvulationDay();
                        bool isOvulationDay = dayInCycle == ovulationDay;

                        return Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getPhaseColor(phase),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: _getPhaseColor(phase)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (isToday)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF333333),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                if (isOvulationDay)
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF333333),
                                        width: 1.5,
                                        strokeAlign:
                                            BorderSide.strokeAlignOutside,
                                      ),
                                    ),
                                  ),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: const Color(0xFF333333),
                                    fontWeight: isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: isToday ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // Bottom Navigation with 5 Items + Center Plus
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              BottomNavigationBar(
                currentIndex: _selectedNavIndex == 2 ? 1 : _selectedNavIndex,
                onTap: (index) {
                  setState(() {
                    _selectedNavIndex = index;
                  });
                  if (index == 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Trackers coming soon!')),
                    );
                  } else if (index == 4) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Analysis coming soon!')),
                    );
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.calendar_month),
                    label: 'Calendar',
                  ),
                  BottomNavigationBarItem(
                    icon: SizedBox.shrink(),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.trending_up),
                    label: 'Trackers',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.bar_chart),
                    label: 'Analysis',
                  ),
                ],
                selectedItemColor: const Color(0xFF333333),
                unselectedItemColor: Colors.grey,
                backgroundColor: Colors.white,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
              ),
              // Plus Button (Floating in the middle)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF333333),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedNavIndex = 2;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Add period coming soon!')),
                        );
                      },
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPhaseExtension() {
    return 'Day $_cycleLength - last cycle day';
  }
}

/// Modal popup for day details with lifestyle recommendations
class DayDetailsModal extends StatefulWidget {
  final DateTime date;
  final String phase;
  final DateTime lastPeriodStart;
  final int cycleLength;

  const DayDetailsModal({
    super.key,
    required this.date,
    required this.phase,
    required this.lastPeriodStart,
    required this.cycleLength,
  });

  @override
  State<DayDetailsModal> createState() => _DayDetailsModalState();
}

class _DayDetailsModalState extends State<DayDetailsModal> {
  late Phase? _phaseData;
  bool _nutrition = false;
  bool _fitness = false;
  bool _mood = false;
  bool _wellness = false;
  Map<String, bool> _trackedExercises = {}; // Track exercise completion status

  static const List<String> _fitnessExercises = [
    'Walking',
    'Yoga',
    'Pilates',
    'Swimming',
    'Cycling',
    'Stretching',
    'Tai Chi',
    'Light Dance',
  ];

  @override
  void initState() {
    super.initState();
    _phaseData = CyclePhases.findPhaseByName(widget.phase);
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nutrition = prefs.getBool('lifestyle_nutrition') ?? false;
      _fitness = prefs.getBool('lifestyle_fitness') ?? false;
      _mood = prefs.getBool('lifestyle_mood') ?? false;
      _wellness = prefs.getBool('lifestyle_wellness') ?? false;

      // Load tracked exercises for this date
      String dateKey = 'fitness_${widget.date.toIso8601String().split('T')[0]}';
      String? trackedStr = prefs.getString(dateKey);
      if (trackedStr != null) {
        _trackedExercises = {};
        List<String> items = trackedStr.split(',');
        for (String item in items) {
          List<String> parts = item.split(':');
          if (parts.length == 2) {
            _trackedExercises[parts[0]] = parts[1] == 'true';
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    int dayOfCycle = (widget.date.difference(widget.lastPeriodStart).inDays %
            widget.cycleLength) +
        1;
    String dateStr = widget.date.toLocal().toString().split(' ')[0];

    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Phase Card - Hero Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            getPhaseColor(widget.phase),
                            getPhaseColor(widget.phase).withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day $dayOfCycle',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Text(
                                          _phaseData?.emoji ?? '🌙',
                                          style: const TextStyle(fontSize: 40),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.phase,
                                                style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF333333),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              if (_phaseData != null)
                                                Text(
                                                  _phaseData!.getDayRange(
                                                      widget.cycleLength),
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Description Section
                    if (_phaseData != null) ...[
                      Text(
                        'Energy Level',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _phaseData!.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF333333),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Recommendations Section
                    Text(
                      'Your Lifestyle Plan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_nutrition) ...[
                      _buildNutritionCircles(),
                      const SizedBox(height: 16),
                    ],
                    if (_fitness) ...[
                      _buildFitnessTile(),
                      const SizedBox(height: 16),
                    ],
                    if (_mood) ...[
                      _buildDashboardTile(
                        emoji: '😊',
                        title: 'Mood & Productivity',
                        subtitle: 'Balance your energy',
                        value: _phaseData?.description ?? 'Focus on balance',
                        onEdit: null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (_wellness) ...[
                      _buildDashboardTile(
                        emoji: '🌙',
                        title: 'Wellness',
                        subtitle: 'Rest & Recovery',
                        value: 'Prioritize sleep and hydration',
                        onEdit: null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_nutrition || _fitness || _mood || _wellness) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF333333),
                            elevation: 0,
                            side: const BorderSide(
                                color: Color(0xFF333333), width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Track More Stuff'),
                        ),
                      ),
                    ],

                    if (!_nutrition && !_fitness && !_mood && !_wellness) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Text(
                          'No lifestyle preferences selected. Update your preferences in settings to see personalized recommendations.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.amber.shade900,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTile({
    required String emoji,
    required String title,
    required String subtitle,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF999999),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Icon(
                    Icons.edit,
                    size: 20,
                    color: Color(0xFF666666),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCircles() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionMealsScreen(
              dietType: _phaseData?.dietName ?? 'Balanced Nutrition',
              phase: widget.phase,
              date: widget.date,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text('🍎', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nutrition',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phaseData?.dietName ?? 'Balanced diet',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 20,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessTile() {
    return GestureDetector(
      onTap: _showFitnessSuggestions,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text('🏋️', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitness',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _phaseData?.workoutName ?? 'Moderate exercise',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 20,
              color: Color(0xFF666666),
            ),
          ],
        ),
      ),
    );
  }

  void _showFitnessSuggestions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Low-Impact Training',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _fitnessExercises.length,
                itemBuilder: (context, index) {
                  String exercise = _fitnessExercises[index];
                  bool isAdded = _trackedExercises.containsKey(exercise);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isAdded) {
                            _trackedExercises.remove(exercise);
                          } else {
                            _trackedExercises[exercise] = false;
                          }
                        });
                        _saveTrackedExercises();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: isAdded
                              ? Colors.grey.shade200
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isAdded
                                ? const Color(0xFF333333)
                                : Colors.grey.shade300,
                            width: isAdded ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              exercise,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF333333),
                                decoration:
                                    isAdded ? TextDecoration.none : null,
                              ),
                            ),
                            if (isAdded)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF333333),
                                size: 24,
                              )
                            else
                              const Icon(
                                Icons.add_circle_outline,
                                color: Color(0xFF999999),
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTrackedExercises() async {
    final prefs = await SharedPreferences.getInstance();
    String dateKey = 'fitness_${widget.date.toIso8601String().split('T')[0]}';
    if (_trackedExercises.isEmpty) {
      await prefs.remove(dateKey);
    } else {
      String tracked =
          _trackedExercises.entries.map((e) => '${e.key}:${e.value}').join(',');
      await prefs.setString(dateKey, tracked);
    }
  }
}
