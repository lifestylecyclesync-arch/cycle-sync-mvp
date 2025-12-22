import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';
import '../utils/avatar_manager.dart';
import 'nutrition_meals_screen.dart';
import 'fitness_suggestions_screen.dart';
import 'fasting_suggestions_screen.dart';
import 'lifestyle_preferences_screen.dart';
import 'profile_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Cycle data loaded from SharedPreferences
  late DateTime _lastPeriodStart;
  late int _cycleLength;
  bool _isLoading = true;

  // Filter state
  String _selectedFilter = 'phases'; // 'phases', 'workouts', 'meals'
  Set<DateTime> _workoutDates = {};
  Map<DateTime, Set<String>> _mealDates = {}; // DateTime -> Set of meal types

  // Avatar refresh mechanism
  int _avatarRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadCycleData();
    _loadFilterData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh avatar when returning to this screen
    setState(() {
      _avatarRefreshKey++;
    });
  }

  Future<void> _loadFilterData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load workouts
    final workoutJson = prefs.getString('fitness_logs') ?? '';
    Set<DateTime> workouts = {};
    if (workoutJson.isNotEmpty) {
      try {
        for (var entry in workoutJson.split('|')) {
          if (entry.isNotEmpty && entry.contains(':')) {
            final date = DateTime.parse(entry.split(':')[0]);
            workouts.add(DateTime(date.year, date.month, date.day));
          }
        }
      } catch (_) {}
    }
    
    // Load meals
    final mealsJson = prefs.getString('meals_logs') ?? '';
    Map<DateTime, Set<String>> meals = {};
    if (mealsJson.isNotEmpty) {
      try {
        for (var entry in mealsJson.split('|')) {
          if (entry.isNotEmpty && entry.contains(':')) {
            final parts = entry.split(':');
            final date = DateTime.parse(parts[0]);
            final dateKey = DateTime(date.year, date.month, date.day);
            final mealType = parts.length > 2 ? parts[2] : 'meal';
            meals.putIfAbsent(dateKey, () => {}).add(mealType);
          }
        }
      } catch (_) {}
    }

    setState(() {
      _workoutDates = workouts;
      _mealDates = meals;
    });
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

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  Color _getPastelColor(String initials) {
    final colors = [
      const Color(0xFFFFB3BA), // Pastel pink
      const Color(0xFFFFDFBA), // Pastel peach
      const Color(0xFFFFFABA), // Pastel yellow
      const Color(0xFFBAFFBA), // Pastel green
      const Color(0xFFBAE1FF), // Pastel blue
      const Color(0xFFE0BBE4), // Pastel purple
      const Color(0xFFFFBBE3), // Pastel magenta
    ];
    final hashCode = initials.hashCode;
    return colors[hashCode % colors.length];
  }

  Color _getPhaseColor(String phase) {
    return getPhaseColor(phase);
  }

  Color _getFilteredDayColor(DateTime day) {
    switch (_selectedFilter) {
      case 'workouts':
        final dateKey = DateTime(day.year, day.month, day.day);
        return _workoutDates.contains(dateKey) 
          ? Colors.blue.shade400  // Has workout
          : Colors.grey.shade200; // No workout
      
      case 'meals':
        final dateKey = DateTime(day.year, day.month, day.day);
        if (_mealDates.containsKey(dateKey)) {
          final mealTypes = _mealDates[dateKey]!;
          if (mealTypes.contains('breakfast') || mealTypes.contains('lunch')) {
            return Colors.orange.shade400; // Has meal
          } else if (mealTypes.contains('dinner')) {
            return Colors.red.shade400; // Has dinner
          } else if (mealTypes.contains('snack')) {
            return Colors.amber.shade400; // Has snack
          }
        }
        return Colors.grey.shade200; // No meals
      
      case 'phases':
      default:
        String phase = _getCyclePhase(day);
        return _getPhaseColor(phase);
    }
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

  Widget _buildFilterButton(String label, String filterType) {
    bool isSelected = _selectedFilter == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filterType;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.pink.shade200 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.pink.shade400 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF333333) : const Color(0xFF666666),
          ),
        ),
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
            // Fixed Header - Standardized Gradient Styling
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.3),
                    _getPhaseColor(_getCurrentPhase()).withValues(alpha: 0.15),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day ${_getCurrentCycleDay()} • ${getPhaseEmoji(_getCurrentPhase())} ${_getCurrentPhase()} phase',
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xFF333333),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPhaseExtension(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: FutureBuilder<List<Object>>(
                        key: ValueKey(_avatarRefreshKey),
                        future: Future.wait([
                          SharedPreferences.getInstance(),
                          AvatarManager.getSelectedAvatar().then((avatar) => avatar ?? AvatarManager.getDefaultAvatar()),
                        ]),
                        builder: (context, snapshot) {
                          String userName = 'Guest';
                          AvatarOption? avatar;
                          
                          if (snapshot.hasData) {
                            final prefs = snapshot.data![0] as SharedPreferences;
                            avatar = snapshot.data![1] as AvatarOption?;
                            final savedName = prefs.getString('userName') ?? '';
                            userName = savedName.isEmpty ? 'Guest' : savedName;
                          }
                          
                          final initials = _getInitials(userName);
                          final pastelColor = _getPastelColor(initials);
                          
                          if (avatar?.isPhoto == true && avatar?.photoPath != null) {
                            return CircleAvatar(
                              radius: 24,
                              backgroundImage: FileImage(File(avatar!.photoPath!)),
                            );
                          }
                          
                          return CircleAvatar(
                            radius: 24,
                            backgroundColor: avatar?.color ?? pastelColor,
                            child: Text(
                              avatar?.emoji ?? initials,
                              style: TextStyle(
                                fontSize: avatar != null ? 16 : 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
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
                  child: Column(
                    children: [
                      // Filter Selector
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFilterButton('📅 Phases', 'phases'),
                            _buildFilterButton('💪 Workouts', 'workouts'),
                            _buildFilterButton('🍽️ Meals', 'meals'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TableCalendar(
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
                              color: _getFilteredDayColor(day),
                              boxShadow: isToday
                                  ? [
                                      BoxShadow(
                                        color: _getFilteredDayColor(day)
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getPhaseExtension() {
    String currentPhase = _getCurrentPhase();
    Phase? phase = CyclePhases.findPhaseByName(currentPhase);
    if (phase != null) {
      return phase.getDayRange(_cycleLength);
    }
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
  bool _fasting = false;
  bool _mood = false;
  bool _wellness = false;
  List<String> _selectedWorkouts = []; // Selected workouts for this date
  Map<String, String> _selectedMeals = {}; // Selected meals: {mealType: mealName}
  String? _selectedFasting; // Selected fasting option
  List<String> _userSymptoms = [];
  List<String> _loggedSymptoms = [];
  String _notes = '';

  @override
  void initState() {
    super.initState();
    _phaseData = CyclePhases.findPhaseByName(widget.phase);
    _loadUserPreferences();
    _loadSymptomsAndNotes();
  }

  Future<void> _loadSymptomsAndNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.date.toIso8601String().split('T')[0];
    final symptomsJson = prefs.getString('userSymptoms');
    final loggedSymptomsJson = prefs.getString('logged_symptoms_$dateKey');
    final notesText = prefs.getString('notes_$dateKey') ?? '';
    
    if (symptomsJson != null) {
      _userSymptoms = symptomsJson.split(',').where((s) => s.isNotEmpty).toList();
    }
    
    if (loggedSymptomsJson != null) {
      _loggedSymptoms = loggedSymptomsJson.split(',').where((s) => s.isNotEmpty).toList();
    }
    
    setState(() {
      _notes = notesText;
    });
  }

  Future<void> _saveSymptomsAndNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = widget.date.toIso8601String().split('T')[0];
    
    await prefs.setString('logged_symptoms_$dateKey', _loggedSymptoms.join(','));
    await prefs.setString('notes_$dateKey', _notes);
  }

  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nutrition = prefs.getBool('lifestyle_nutrition') ?? false;
      _fitness = prefs.getBool('lifestyle_fitness') ?? false;
      _fasting = prefs.getBool('lifestyle_fasting') ?? false;
      _mood = prefs.getBool('lifestyle_mood') ?? false;
      _wellness = prefs.getBool('lifestyle_wellness') ?? false;

      // Load selected workouts for this date
      String dateKey = 'fitness_${widget.date.toIso8601String().split('T')[0]}';
      String? selectedStr = prefs.getString(dateKey);
      if (selectedStr != null && selectedStr.isNotEmpty) {
        // Handle both new format (comma-separated) and old format (colon-separated with booleans)
        if (selectedStr.contains(':')) {
          // Old format: "walking:true,yoga:false" - extract only true values
          _selectedWorkouts = [];
          List<String> items = selectedStr.split(',');
          for (String item in items) {
            List<String> parts = item.split(':');
            if (parts.length == 2 && parts[1] == 'true') {
              _selectedWorkouts.add(parts[0]);
            }
          }
        } else {
          // New format: "walking,yoga,pilates"
          _selectedWorkouts = selectedStr.split(',').where((item) => item.isNotEmpty).toList();
        }
      } else {
        _selectedWorkouts = [];
      }

      // Load selected meals for this date
      final mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
      _selectedMeals = {};
      for (String mealType in mealTypes) {
        String mealDateKey = 'nutrition_${widget.date.toIso8601String().split('T')[0]}_$mealType';
        String? selectedMeal = prefs.getString(mealDateKey);
        if (selectedMeal != null && selectedMeal.isNotEmpty) {
          _selectedMeals[mealType] = selectedMeal;
        }
      }

      // Load selected fasting for this date
      String fastingDateKey = 'fasting_${widget.date.toIso8601String().split('T')[0]}';
      _selectedFasting = prefs.getString(fastingDateKey);
    });
  }

  void _showSymptomsAndNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.pink.shade100),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Log Symptoms & Notes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.close, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track how you felt on ${widget.date.toString().split(' ')[0]}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Symptoms Section
                          if (_userSymptoms.isNotEmpty) ...[
                            const Text(
                              'How did you feel?',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.pink.shade100),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: _userSymptoms.asMap().entries.map((entry) {
                                  int index = entry.key;
                                  String symptom = entry.value;
                                  bool isChecked = _loggedSymptoms.contains(symptom);
                                  
                                  return Column(
                                    children: [
                                      CheckboxListTile(
                                        title: Text(symptom),
                                        value: isChecked,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            if (value == true) {
                                              _loggedSymptoms.add(symptom);
                                            } else {
                                              _loggedSymptoms.remove(symptom);
                                            }
                                          });
                                        },
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                        activeColor: Colors.pink,
                                      ),
                                      if (index < _userSymptoms.length - 1)
                                        Divider(height: 1, color: Colors.pink.shade50),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ] else
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: const Text(
                                'Go to Profile to select symptoms to track.',
                                style: TextStyle(fontSize: 12, color: Colors.amber),
                              ),
                            ),
                          // Notes Section
                          const Text(
                            'Add a note',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            maxLines: 4,
                            onChanged: (value) {
                              setState(() {
                                _notes = value;
                              });
                            },
                            controller: TextEditingController(text: _notes),
                            decoration: InputDecoration(
                              hintText: 'How are you feeling today?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.pink.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Colors.pink),
                              ),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer with Save button
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.pink.shade100),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await _saveSymptomsAndNotes();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Symptoms & notes saved!'),
                                backgroundColor: Colors.pink,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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
                    // Phase Card - Compact Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
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
                                child: Row(
                                  children: [
                                    Text(
                                      _phaseData?.emoji ?? '🌙',
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.phase,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Day $dayOfCycle • $dateStr',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF666666),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 24),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description Section
                    if (_phaseData != null) ...[
                      Text(
                        'Energy Level',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _phaseData!.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF333333),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Recommendations Section
                    Text(
                      'Your Lifestyle Plan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_nutrition) ...[
                      _buildNutritionCircles(),
                      const SizedBox(height: 12),
                    ],
                    if (_fitness) ...[
                      _buildFitnessTile(),
                      const SizedBox(height: 12),
                    ],
                    if (_fasting) ...[
                      _buildFastingTile(),
                      const SizedBox(height: 12),
                    ],
                    if (_mood) ...[
                      _buildDashboardTile(
                        emoji: '😊',
                        title: 'Mood & Productivity',
                        subtitle: 'Balance your energy',
                        value: _phaseData?.description ?? 'Focus on balance',
                        onEdit: null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_wellness) ...[
                      _buildDashboardTile(
                        emoji: '🌙',
                        title: 'Wellness',
                        subtitle: 'Rest & Recovery',
                        value: 'Prioritize sleep and hydration',
                        onEdit: null,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_nutrition || _fitness || _fasting || _mood || _wellness) ...[
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LifestylePreferencesScreen(),
                              ),
                            ).then((result) {
                              if (result == true && mounted) {
                                // Reload preferences when returning
                                setState(() {});
                                _loadUserPreferences();
                              }
                            });
                          },
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

                    if (!_nutrition && !_fitness && !_fasting && !_mood && !_wellness) ...[
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

                    // Symptoms & Notes Section
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: _showSymptomsAndNotes,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '➕ Log Symptoms & Notes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Track how you feel today',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.pink.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: Colors.pink.shade600),
                          ],
                        ),
                      ),
                    ),
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
    String displayText = _selectedMeals.isEmpty
        ? (_phaseData?.dietName ?? 'Balanced Nutrition')
        : _selectedMeals.entries
            .map((e) => '${e.key.capitalize()}: ${e.value}')
            .join('\n');

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
        ).then((_) async {
          // Reload meals after returning from NutritionMealsScreen
          if (mounted) {
            await _loadUserPreferences();
          }
        });
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
                    displayText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.clip,
                  ),
                  if (_selectedMeals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tap to add meals →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 22,
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFitnessTile() {
    String displayText = _selectedWorkouts.isEmpty
        ? (_phaseData?.workoutName ?? 'Moderate exercise')
        : _selectedWorkouts.join(', ');

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
                    displayText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_selectedWorkouts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tap to add workouts →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 22,
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFastingTile() {
    String displayText = _selectedFasting?.isEmpty ?? true
        ? (_phaseData?.fastingType ?? 'No Fasting')
        : _selectedFasting!;

    return GestureDetector(
      onTap: _showFastingSuggestions,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Text('⏱️', style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fasting',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((_selectedFasting?.isEmpty ?? true))
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Tap to select fasting →',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 22,
              color: Color(0xFF333333),
            ),
          ],
        ),
      ),
    );
  }

  void _showFitnessSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FitnessSuggestionsScreen(
          workoutType: _phaseData?.workoutName ?? 'Fitness',
          phase: widget.phase,
          date: widget.date,
        ),
      ),
    ).then((_) async {
      // Reload workouts after returning from FitnessSuggestionsScreen
      if (mounted) {
        await _loadUserPreferences();
      }
    });
  }

  void _showFastingSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FastingSuggestionsScreen(
          fastingType: _phaseData?.fastingType ?? 'No Fasting',
          phase: widget.phase,
          date: widget.date,
        ),
      ),
    ).then((_) async {
      // Reload fasting after returning from FastingSuggestionsScreen
      if (mounted) {
        await _loadUserPreferences();
      }
    });
  }


}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
