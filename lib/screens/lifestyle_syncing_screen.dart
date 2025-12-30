import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';
import '../utils/goal_manager.dart';
import 'fitness_suggestions_screen.dart';

class LifestyleSyncingScreen extends StatefulWidget {
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int menstrualLength;

  const LifestyleSyncingScreen({
    super.key,
    required this.lastPeriodStart,
    required this.cycleLength,
    this.menstrualLength = 5,
  });

  @override
  State<LifestyleSyncingScreen> createState() => _LifestyleSyncingScreenState();
}

class _LifestyleSyncingScreenState extends State<LifestyleSyncingScreen> {
  late String _currentPhase;
  late Phase? _currentPhaseData;
  late int _currentCycleDay;
  late DateTime _today;

  // Customized suggestions
  String _nutritionSuggestion = '';
  String _fitnessSuggestion = '';
  List<String> _selectedWorkouts = [];
  String _fastingSuggestion = '';
  List<Goal> _goals = []; // Load goals for display

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentCycleDay = (_today.difference(widget.lastPeriodStart).inDays % widget.cycleLength) + 1;
    _currentPhase = getCyclePhase(widget.lastPeriodStart, widget.cycleLength, _today, menstrualLength: widget.menstrualLength);
    _currentPhaseData = CyclePhases.findPhaseByName(_currentPhase);
    _loadCustomizations();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final goals = await GoalManager.getAllGoals();
    setState(() {
      _goals = goals;
    });
  }

  Future<void> _loadCustomizations() async {
    final prefs = await SharedPreferences.getInstance();
    String todayKey = _today.toIso8601String().split('T')[0];
    
    setState(() {
      _nutritionSuggestion = prefs.getString('nutrition_suggestion') ??
          _currentPhaseData?.dietName ??
          'Balanced diet';
      // Load today's fitness workouts (date-specific, multiple selections)
      final fitnessData = prefs.getString('fitness_$todayKey');
      if (fitnessData != null && fitnessData.isNotEmpty) {
        _selectedWorkouts = fitnessData.split(',');
        _fitnessSuggestion = _selectedWorkouts.join(', ');
      } else {
        _selectedWorkouts = [];
        _fitnessSuggestion = _currentPhaseData?.workoutName ?? 'Moderate exercise';
      }
      _fastingSuggestion = prefs.getString('fasting_suggestion') ??
          _getDefaultFastingForPhase(_currentPhase) ??
          'IF 16';
    });
  }

  Future<void> _saveSuggestion(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  String? _getDefaultFastingForPhase(String phase) {
    switch (phase) {
      case 'Menstrual':
        return 'No fasting';
      case 'Follicular':
        return 'IF 14';
      case 'Ovulation':
        return 'IF 15';
      case 'Early Luteal':
        return 'IF 13';
      case 'Luteal':
        return 'IF 12';
      default:
        return 'IF 16';
    }
  }

  String _getPhaseRange(String phaseName) {
    // Calculate day ranges based on cycle parameters using new phase boundaries:
    // - Menstrual: Day 1–periodLength
    // - Follicular: Day (periodLength+1)–(ovulationDay-2)
    // - Ovulation: Day (ovulationDay-1)–(ovulationDay+1)
    // - Early Luteal: Day (ovulationDay+2)–(ovulationDay+5)
    // - Luteal: Day (ovulationDay+6)–cycleLength
    final ovulationDay = widget.cycleLength - 14;
    
    switch (phaseName) {
      case 'Menstrual':
        return 'Days 1–${widget.menstrualLength}';
      case 'Follicular':
        return 'Days ${widget.menstrualLength + 1}–${ovulationDay - 2}';
      case 'Ovulation':
        return 'Days ${ovulationDay - 1}–${ovulationDay + 1}';
      case 'Early Luteal':
        return 'Days ${ovulationDay + 2}–${ovulationDay + 5}';
      case 'Luteal':
        return 'Days ${ovulationDay + 6}–${widget.cycleLength}';
      default:
        return 'Days 1–${widget.cycleLength}';
    }
  }

  void _showEditDialog(String title, String currentValue, String key) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (key == 'fitness_suggestion') ...[
              Text(
                'Recommended for ${_currentPhase} phase:',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  _currentPhaseData?.workoutName ?? 'Moderate exercise',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Or customize:',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Enter $title suggestion',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              String newValue = controller.text;
              if (newValue.isNotEmpty) {
                _saveSuggestion(key, newValue);
                setState(() {
                  if (key == 'nutrition_suggestion') {
                    _nutritionSuggestion = newValue;
                  } else if (key == 'fitness_suggestion') {
                    _fitnessSuggestion = newValue;
                  } else if (key == 'fasting_suggestion') {
                    _fastingSuggestion = newValue;
                  }
                });
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Header with Cycle Day and Phase - Standardized Gradient Styling
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      getPhaseColor(_currentPhase).withValues(alpha: 0.3),
                      getPhaseColor(_currentPhase).withValues(alpha: 0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $_currentCycleDay • ${_currentPhaseData?.emoji ?? ''} ${_currentPhase} phase',
                      style: const TextStyle(
                        fontSize: 22,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_getPhaseRange(_currentPhaseData?.name ?? 'Menstrual')} • ${_currentPhaseData?.workoutName ?? 'Unknown'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lifestyle Syncing',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Lifestyle Cards
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Nutrition Card
                      _buildLifestyleCard(
                        emoji: '🍎',
                        title: 'Nutrition',
                        suggestion: _nutritionSuggestion,
                        relatedGoals: _goals.where((g) => g.type == 'nutrition').toList(),
                        onEdit: () => _showEditDialog(
                          _currentPhaseData?.dietName ?? 'Nutrition',
                          _nutritionSuggestion,
                          'nutrition_suggestion',
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Fitness Card
                      _buildLifestyleCard(
                        emoji: '🏋️',
                        title: 'Fitness',
                        suggestion: _fitnessSuggestion,
                        relatedGoals: _goals.where((g) => g.type == 'exercise').toList(),
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FitnessSuggestionsScreen(
                              workoutType: _currentPhaseData?.workoutName ?? 'Fitness',
                              phase: _currentPhase,
                              date: _today,
                            ),
                          ),
                        ).then((_) {
                          // Reload fitness suggestion after returning
                          _loadCustomizations();
                          _loadGoals(); // Reload goals too
                        }),
                      ),
                      const SizedBox(height: 15),

                      // Fasting Card
                      _buildLifestyleCard(
                        emoji: '⏱️',
                        title: 'Fasting',
                        suggestion: _fastingSuggestion,
                        relatedGoals: _goals.where((g) => g.type == 'wellness').toList(),
                        onEdit: () => _showEditDialog(
                          'Fasting',
                          _fastingSuggestion,
                          'fasting_suggestion',
                        ),
                      ),
                      const SizedBox(height: 30),
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

  Widget _buildLifestyleCard({
    required String emoji,
    required String title,
    required String suggestion,
    required List<Goal> relatedGoals,
    required VoidCallback onEdit,
  }) {
    // Determine pastel color based on title
    Color cardColor;
    switch (title) {
      case 'Nutrition':
        cardColor = const Color(0xFFEDD8D8); // Faded Pink
        break;
      case 'Fitness':
        cardColor = const Color(0xFFD8EFF8); // Faded Sky Blue
        break;
      case 'Fasting':
        cardColor = const Color(0xFFE8D8F8); // Faded Lavender
        break;
      default:
        cardColor = Colors.grey.shade100;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          GestureDetector(
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Emoji
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 15),

                  // Title and Suggestion
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF333333),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Tap to customize →',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.edit,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Daily Goals Section
          if (relatedGoals.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily Goals',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...relatedGoals.map((goal) {
                          final isCompletedToday = goal.isCompletedToday();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Icon(
                                  isCompletedToday
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isCompletedToday
                                      ? Colors.green
                                      : Colors.grey.shade400,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: isCompletedToday
                                              ? Colors.green
                                              : Colors.black87,
                                          decoration: isCompletedToday
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                        ),
                                      ),
                                      Text(
                                        goal.amount,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
