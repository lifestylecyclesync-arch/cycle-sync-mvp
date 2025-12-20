import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';

class LifestyleSyncingScreen extends StatefulWidget {
  final DateTime lastPeriodStart;
  final int cycleLength;

  const LifestyleSyncingScreen({
    super.key,
    required this.lastPeriodStart,
    required this.cycleLength,
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
  String _fastingSuggestion = '';

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _currentCycleDay = (_today.difference(widget.lastPeriodStart).inDays % widget.cycleLength) + 1;
    _currentPhase = getCyclePhase(widget.lastPeriodStart, widget.cycleLength, _today);
    _currentPhaseData = CyclePhases.findPhaseByName(_currentPhase);
    _loadCustomizations();
  }

  Future<void> _loadCustomizations() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nutritionSuggestion = prefs.getString('nutrition_suggestion') ??
          _currentPhaseData?.dietName ??
          'Balanced diet';
      _fitnessSuggestion = prefs.getString('fitness_suggestion') ??
          _currentPhaseData?.workoutName ??
          'Moderate exercise';
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

  void _showEditDialog(String title, String currentValue, String key) {
    TextEditingController controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter $title suggestion',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
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
              // Header with Cycle Day and Phase
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $_currentCycleDay — ${_currentPhase} ${_currentPhaseData?.emoji ?? ''}',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF333333),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentPhaseData?.getDayRange(widget.cycleLength) ?? 'Days 1–28',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lifestyle Syncing',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
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
                        onEdit: () => _showEditDialog(
                          'Nutrition',
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
                        onEdit: () => _showEditDialog(
                          'Fitness',
                          _fitnessSuggestion,
                          'fitness_suggestion',
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Fasting Card
                      _buildLifestyleCard(
                        emoji: '⏱️',
                        title: 'Fasting',
                        suggestion: _fastingSuggestion,
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
      padding: const EdgeInsets.all(16.0),
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
              ],
            ),
          ),

          // Edit Button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              child: const Icon(
                Icons.edit,
                size: 18,
                color: Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
