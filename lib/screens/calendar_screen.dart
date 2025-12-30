import 'dart:io';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/gradient_wrapper.dart';
import '../utils/cycle_utils.dart';
import '../models/phase.dart';
import '../utils/avatar_manager.dart';
import '../utils/goal_manager.dart';
import 'nutrition_meals_screen.dart';
import 'fitness_suggestions_screen.dart';
import 'fasting_suggestions_screen.dart';
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
  late int _menstrualLength;
  bool _isLoading = true;

  // Filter state
  String _selectedFilter = 'phases'; // 'phases', 'goals', or specific goal type
  List<Goal> _goals = [];
  Map<String, Map<DateTime, bool>> _goalCompletions = {}; // goalId -> (date -> completed)
  Set<String> _manualFilters = {}; // Manually added goal categories (persist across goal deletion)
  bool _showMonthlySummary = false; // Expandable monthly summary

  // Avatar refresh mechanism
  int _avatarRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadCycleData();
    _loadFilterData();
    _loadManualFilters();
    _loadGoals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh avatar and goals when returning to this screen
    setState(() {
      _avatarRefreshKey++;
    });
    _loadManualFilters();
    _loadGoals();
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
      // Data loaded - no longer needed for current implementation
    });
  }

  Future<void> _loadGoals() async {
    final goals = await GoalManager.getAllGoals();
    final completions = <String, Map<DateTime, bool>>{};
    
    for (final goal in goals) {
      completions[goal.id] = {};
      for (final dateStr in goal.completedDates) {
        try {
          final date = DateTime.parse(dateStr);
          completions[goal.id]![DateTime(date.year, date.month, date.day)] = true;
        } catch (e) {
          // Skip invalid dates
        }
      }
    }
    
    setState(() {
      _goals = goals;
      _goalCompletions = completions;
    });
  }

  /// Load manually added filters from SharedPreferences
  Future<void> _loadManualFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final manualFiltersJson = prefs.getString('calendar_manual_filters') ?? '';
    
    final filters = <String>{};
    if (manualFiltersJson.isNotEmpty) {
      try {
        filters.addAll(manualFiltersJson.split(',').where((f) => f.isNotEmpty));
      } catch (e) {
        // Skip invalid data
      }
    }
    
    setState(() {
      _manualFilters = filters;
    });
  }

  /// Save manually added filters to SharedPreferences
  Future<void> _saveManualFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_manual_filters', _manualFilters.join(','));
  }

  /// Add a filter manually (without requiring a goal)
  void _addManualFilter(String goalType) async {
    setState(() {
      _manualFilters.add(goalType);
    });
    await _saveManualFilters();
  }

  /// Show dialog to add a new filter category manually
  void _showAddFilterDialog() {
    final allTypes = ['exercise', 'water', 'sleep', 'meditation', 'nutrition', 'weightloss', 'wellness'];
    final usedTypes = _goals.map((g) => g.type).toSet();
    final availableTypes = allTypes.where((t) => !usedTypes.contains(t) && !_manualFilters.contains(t)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category to Track'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (availableTypes.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'All categories are either tracked or already added!',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableTypes.map((type) {
                  final emoji = _getGoalEmoji(type);
                  final label = type[0].toUpperCase() + type.substring(1);
                  return GestureDetector(
                    onTap: () {
                      _addManualFilter(type);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade400),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(emoji),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCycleData() async {
    final prefs = await SharedPreferences.getInstance();

    String? lastPeriodStr = prefs.getString('lastPeriodStart');
    _lastPeriodStart = lastPeriodStr != null
        ? DateTime.parse(lastPeriodStr)
        : DateTime(2024, 11, 28);

    _cycleLength = prefs.getInt('cycleLength') ?? 28;
    _menstrualLength = prefs.getInt('periodLength') ?? 5;

    setState(() {
      _isLoading = false;
    });
  }

  int _getCurrentCycleDay() {
    int daysSinceStart = DateTime.now().difference(_lastPeriodStart).inDays;
    return (daysSinceStart % _cycleLength) + 1;
  }

  String _getCurrentPhase() {
    return getCyclePhase(_lastPeriodStart, _cycleLength, DateTime.now(),
        menstrualLength: _menstrualLength);
  }

  String _getCyclePhase(DateTime day) {
    return getCyclePhase(_lastPeriodStart, _cycleLength, day,
        menstrualLength: _menstrualLength);
  }

  bool _isFertileWindow(DateTime day) {
    return isFertileWindow(_lastPeriodStart, _cycleLength, day);
  }

  int _getOvulationDay() {
    return getOvulationDay(_cycleLength);
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

  Color _getGoalTypeColor(String goalType) {
    switch (goalType) {
      case 'Exercise':
        return Colors.green.shade400;
      case 'Water':
        return Colors.blue.shade400;
      case 'Sleep':
        return Colors.indigo.shade400;
      case 'Meditation':
        return Colors.purple.shade400;
      case 'Nutrition':
        return Colors.orange.shade400;
      case 'Weightloss':
        return Colors.red.shade400;
      case 'Wellness':
        return Colors.teal.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  String _getGoalEmoji(String goalType) {
    final lowerType = goalType.toLowerCase();
    switch (lowerType) {
      case 'exercise':
        return '💪';
      case 'water':
        return '💧';
      case 'sleep':
        return '😴';
      case 'meditation':
        return '🧘';
      case 'nutrition':
        return '🥗';
      case 'weightloss':
        return '⚖️';
      case 'wellness':
        return '✨';
      default:
        return '🎯';
    }
  }

  List<String> _getUniqueGoalTypes() {
    final types = _goals.map((goal) => goal.type).toSet().toList();
    return types;
  }

  /// Calculate weekly summary for current month
  List<Map<String, dynamic>> _getWeeklySummaries() {
    if (_selectedFilter == 'phases') return [];
    
    final goalType = _selectedFilter.replaceFirst('goal_type_', '');
    final goalsOfType = _goals.where((g) => g.type == goalType).toList();
    
    if (goalsOfType.isEmpty) return [];
    
    final weekSummaries = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    
    int weekNum = 1;
    var weekStart = monthStart;
    
    while (weekStart.isBefore(monthEnd)) {
      var weekEnd = weekStart.add(const Duration(days: 7));
      if (weekEnd.isAfter(monthEnd)) weekEnd = monthEnd;
      
      int completed = 0;
      int total = 0;
      
      for (int i = 0; i < 7; i++) {
        final checkDate = weekStart.add(Duration(days: i));
        if (checkDate.isAfter(monthEnd)) break;
        
        total++;
        final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
        
        // Check if any goal of this type is completed on this date
        for (final goal in goalsOfType) {
          if (_goalCompletions[goal.id]?[dateKey] ?? false) {
            completed++;
            break; // Count once per day
          }
        }
      }
      
      final targetFrequency = goalsOfType.isNotEmpty 
        ? goalsOfType.first.frequencyValue 
        : 1;
      final percentage = total > 0 ? ((completed / targetFrequency) * 100).toStringAsFixed(0) : '0';
      
      weekSummaries.add({
        'week': weekNum,
        'completed': completed,
        'target': targetFrequency,
        'percentage': int.parse(percentage),
        'startDate': weekStart,
        'endDate': weekEnd,
      });
      
      weekStart = weekEnd.add(const Duration(days: 1));
      weekNum++;
    }
    
    return weekSummaries;
  }

  /// Get trend indicator (↑ or ↓) comparing two weeks
  String _getTrendIndicator(int currentWeek, int previousWeek) {
    if (currentWeek > previousWeek) return '↑';
    if (currentWeek < previousWeek) return '↓';
    return '→';
  }

  Color _getTrendColor(int currentWeek, int previousWeek) {
    if (currentWeek > previousWeek) return Colors.green;
    if (currentWeek < previousWeek) return Colors.red;
    return Colors.grey;
  }

  // Get goal type colors for overlay borders
  Color _getGoalTypeColorForOverlay(String goalType) {
    switch (goalType) {
      case 'Exercise':
      case 'Fitness':
        return Colors.green; // Green for fitness/exercise
      case 'Hydration':
        return Colors.blue; // Blue for hydration
      case 'Fasting':
        return Colors.purple; // Purple for fasting
      case 'Mood':
      case 'Wellness':
        return Colors.teal; // Teal for mood/wellness
      default:
        return Colors.grey.shade400;
    }
  }

  // Build goal overlay borders for a day cell
  List<Widget> _buildGoalOverlayBorders(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    final overlayBorders = <Widget>[];
    
    // Collect all goals for this day
    final goalsForDay = <String, bool>{}; // goalType -> isCompleted
    
    for (final goal in _goals) {
      final isCompleted = _goalCompletions[goal.id]?[dateKey] ?? false;
      if (!goalsForDay.containsKey(goal.type) || isCompleted) {
        goalsForDay[goal.type] = isCompleted;
      }
    }
    
    // If no goals, return empty
    if (goalsForDay.isEmpty) return overlayBorders;
    
    // Build borders for each goal type
    int borderIndex = 0;
    
    goalsForDay.forEach((goalType, isCompleted) {
      final color = _getGoalTypeColorForOverlay(goalType);
      
      overlayBorders.add(
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color,
                width: 1.5,
                // Dashed effect - use strokeAlign to create visual spacing
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            // Slight rotation offset to make multiple borders visible
            transform: Matrix4.identity()
              ..translate(borderIndex * 0.8, borderIndex * 0.8),
          ),
        ),
      );
      borderIndex++;
    });
    
    return overlayBorders;
  }

  Color _getFilteredDayColor(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    
    switch (_selectedFilter) {
      case 'phases':
      default:
        // Check if it's a goal type filter
        if (_selectedFilter.startsWith('goal_type_')) {
          final goalType = _selectedFilter.replaceFirst('goal_type_', '');
          // Get all goals of this type
          final goalsOfType = _goals.where((g) => g.type == goalType).toList();
          
          if (goalsOfType.isEmpty) {
            // Default to phase color if no goals of this type
            String phase = _getCyclePhase(day);
            return _getPhaseColor(phase);
          }
          
          // Check if any goal of this type is completed
          for (var goal in goalsOfType) {
            if (_goalCompletions[goal.id]?[dateKey] ?? false) {
              return _getGoalTypeColor(goal.type); // Goal completed
            }
          }
          return Colors.grey.shade200; // No goals of this type completed
        }
        
        // Default to phase color
        String phase = _getCyclePhase(day);
        return _getPhaseColor(phase);
    }
  }

  void _showDayDetails(DateTime day) {
    String phase = _getCyclePhase(day);
    
    // Get filtered goals for this day based on selected filter
    List<Goal> filteredGoals = [];
    Map<String, dynamic> progressMetrics = {};
    String noGoalMessage = ''; // Message if viewing manual filter without active goal
    
    if (_selectedFilter != 'phases') {
      // Check if it's a goal type filter
      if (_selectedFilter.startsWith('goal_type_')) {
        final goalType = _selectedFilter.replaceFirst('goal_type_', '');
        // Get all goals of this type
        filteredGoals = _goals.where((g) => g.type == goalType).toList();
        
        // Check if this is a manual filter without an active goal
        if (filteredGoals.isEmpty && _manualFilters.contains(goalType)) {
          noGoalMessage = 'No active goal set for this category.\nTap to set a goal.';
        }
        
        if (filteredGoals.isNotEmpty) {
          progressMetrics = _calculateCombinedGoalProgress(filteredGoals);
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DayDetailsModal(
        date: day,
        phase: phase,
        lastPeriodStart: _lastPeriodStart,
        cycleLength: _cycleLength,
        menstrualLength: _menstrualLength,
        filteredGoals: filteredGoals,
        goalCompletions: _goalCompletions,
        onGoalCompletionChanged: _onGoalCompletionChanged,
        progressMetrics: progressMetrics,
        noGoalMessage: noGoalMessage,
      ),
    );
  }

  Map<String, dynamic> _calculateCombinedGoalProgress(List<Goal> goals) {
    if (goals.isEmpty) {
      return {
        'completed': 0,
        'total': 0,
        'percentage': 0,
        'message': 'No goals',
        'timeframe': 'week'
      };
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    // Check if all goals are frequency-based
    final allFrequencyGoals = goals.every((g) => g.type == 'exercise' || g.type == 'meditation' || g.type == 'wellness');

    if (allFrequencyGoals) {
      // Sum all frequency targets for the week
      int weekCompleted = 0;
      int totalFrequency = 0;

      for (var goal in goals) {
        final frequency = goal.frequencyValue;
        totalFrequency += frequency;

        // Count completions this week for this goal
        for (int i = 0; i < 7; i++) {
          final checkDate = weekStart.add(Duration(days: i));
          final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
          if (_goalCompletions[goal.id]?[dateKey] ?? false) {
            weekCompleted++;
          }
        }
      }

      final percentage = totalFrequency > 0 ? (weekCompleted / totalFrequency * 100).toInt() : 0;

      return {
        'completed': weekCompleted,
        'total': totalFrequency,
        'percentage': percentage,
        'message': '$percentage% of weekly target',
        'subtitle': '$weekCompleted of $totalFrequency completions',
        'timeframe': 'week'
      };
    } else {
      // Count completed days this month for all goals combined
      int monthCompleted = 0;
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      for (int day = 1; day <= daysInMonth; day++) {
        final checkDate = DateTime(now.year, now.month, day);
        final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
        
        // Check if any goal of this type is completed on this day
        bool dayHasCompletion = false;
        for (var goal in goals) {
          if (_goalCompletions[goal.id]?[dateKey] ?? false) {
            dayHasCompletion = true;
            break;
          }
        }
        
        if (dayHasCompletion) {
          monthCompleted++;
        }
      }

      final percentage = (monthCompleted / daysInMonth * 100).toInt();

      return {
        'completed': monthCompleted,
        'total': daysInMonth,
        'percentage': percentage,
        'message': '$percentage% of days completed',
        'subtitle': '$monthCompleted of $daysInMonth days',
        'timeframe': 'month'
      };
    }
  }

  Future<void> _onGoalCompletionChanged(String goalId, DateTime date, bool isCompleted) async {
    final goal = _goals.firstWhere((g) => g.id == goalId);
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    if (isCompleted) {
      if (!goal.completedDates.contains(dateStr)) {
        goal.completedDates.add(dateStr);
      }
    } else {
      goal.completedDates.remove(dateStr);
    }
    
    await GoalManager.updateGoal(goal);
    await _loadGoals(); // Reload and update state
    
    // Check if all goals for this day are completed
    if (isCompleted) {
      _checkDayCompletion(date);
    }
  }

  void _checkDayCompletion(DateTime date) {
    final dateKey = DateTime(date.year, date.month, date.day);
    final allGoals = _goals;
    
    if (allGoals.isEmpty) return;
    
    // Check if all goals have been completed on this day
    bool allCompleted = true;
    for (final goal in allGoals) {
      if (!(_goalCompletions[goal.id]?[dateKey] ?? false)) {
        allCompleted = false;
        break;
      }
    }
    
    if (allCompleted) {
      _showCelebration();
    }
  }

  void _showCelebration() {
    showDialog(
      context: context,
      builder: (context) => AchievementCelebrationDialog(
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildGoalTypeProgressSection() {
    final goalType = _selectedFilter.replaceFirst('goal_type_', '');
    final goalsOfType = _goals.where((g) => g.type == goalType).toList();

    if (goalsOfType.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if all goals are frequency-based
    final allFrequencyGoals =
        goalsOfType.every((g) => g.type == 'exercise' || g.type == 'meditation' || g.type == 'wellness');

    if (!allFrequencyGoals) {
      return const SizedBox.shrink();
    }

    // Calculate weekly progress
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));

    int weekCompleted = 0;
    int totalFrequency = 0;

    for (var goal in goalsOfType) {
      final frequency = goal.frequencyValue;
      totalFrequency += frequency;

      // Count completions this week for this goal
      for (int i = 0; i < 7; i++) {
        final checkDate = weekStart.add(Duration(days: i));
        final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
        if (_goalCompletions[goal.id]?[dateKey] ?? false) {
          weekCompleted++;
        }
      }
    }

    final percentage = totalFrequency > 0 ? (weekCompleted / totalFrequency * 100).toInt() : 0;

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            // Goals list
            ...goalsOfType.map((goal) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            goal.getDisplayString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                        Text(
                          '${goal.frequencyValue}x/week',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 12),
            // Overall progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalFrequency > 0 ? weekCompleted / totalFrequency : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 100 ? Colors.green.shade400 : Colors.blue.shade400,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percentage% of weekly target',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: percentage >= 100 ? Colors.green.shade600 : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$weekCompleted of $totalFrequency completions',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build weekly summary card showing progress per week
  Widget _buildWeeklySummaryCard() {
    final weeklySummaries = _getWeeklySummaries();
    
    if (weeklySummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Breakdown',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 12),
            ...weeklySummaries.asMap().entries.map((entry) {
              final week = entry.value;
              final weekNum = week['week'] as int;
              final completed = week['completed'] as int;
              final target = week['target'] as int;
              final percentage = week['percentage'] as int;
              
              // Calculate trend
              String trend = '→';
              Color trendColor = Colors.grey;
              if (entry.key > 0) {
                final prevPercentage = weeklySummaries[entry.key - 1]['percentage'] as int;
                trend = _getTrendIndicator(percentage, prevPercentage);
                trendColor = _getTrendColor(percentage, prevPercentage);
              }
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week $weekNum',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          Text(
                            '$completed/$target',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF999999),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$percentage%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: percentage >= 100 ? Colors.green : Colors.orange,
                          ),
                        ),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 16,
                            color: trendColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build monthly summary card with aggregated statistics
  Widget _buildMonthlySummaryCard() {
    final weeklySummaries = _getWeeklySummaries();
    
    if (weeklySummaries.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalCompleted = 0;
    int totalTarget = 0;
    int bestWeekNum = 0;
    int bestWeekCompleted = 0;
    int missedWeekNum = 0;
    int overAchievedWeekNum = 0;

    for (final week in weeklySummaries) {
      totalCompleted += week['completed'] as int;
      totalTarget += week['target'] as int;
      
      if ((week['completed'] as int) > bestWeekCompleted) {
        bestWeekCompleted = week['completed'] as int;
        bestWeekNum = week['week'] as int;
      }
      
      if ((week['percentage'] as int) < 100 && missedWeekNum == 0) {
        missedWeekNum = week['week'] as int;
      }
      
      if ((week['percentage'] as int) > 100 && overAchievedWeekNum == 0) {
        overAchievedWeekNum = week['week'] as int;
      }
    }

    final monthlyPercentage = totalTarget > 0 ? ((totalCompleted / totalTarget) * 100).toInt() : 0;
    final isGoalAchieved = monthlyPercentage >= 100;

    return Card(
      elevation: 0,
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Monthly Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF666666),
                  ),
                ),
                if (isGoalAchieved)
                  const Text(
                    '🎉 Goal Achieved!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D5016),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Main stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalCompleted/$totalTarget',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Completion Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$monthlyPercentage%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isGoalAchieved ? Colors.green : Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: totalTarget > 0 ? totalCompleted / totalTarget : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isGoalAchieved ? Colors.green.shade400 : Colors.purple.shade400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Highlights
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highlights',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                if (bestWeekNum > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      '✨ Best week: Week $bestWeekNum ($bestWeekCompleted completions)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                if (missedWeekNum > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Text(
                      '⚠️ Missed week: Week $missedWeekNum (below target)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF999999),
                      ),
                    ),
                  ),
                if (overAchievedWeekNum > 0)
                  Text(
                    '🚀 Over-achieved: Week $overAchievedWeekNum (exceeded target)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF666666),
                    ),
                  ),
              ],
            ),
          ],
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
            // Minimalist Header - No Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
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
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getPhaseExtension(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: DropdownButton<String>(
                            value: _selectedFilter,
                            underline: const SizedBox(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'phases',
                                child: Text('📅 Phases'),
                              ),
                              // Goal-based filters
                              if (_goals.isNotEmpty) ...[
                                const DropdownMenuItem(
                                  enabled: false,
                                  value: '',
                                  child: Divider(height: 8),
                                ),
                                ..._getUniqueGoalTypes().map((goalType) {
                                  final emoji = _getGoalEmoji(goalType);
                                  final label = goalType[0].toUpperCase() + goalType.substring(1);
                                  return DropdownMenuItem(
                                    value: 'goal_type_$goalType',
                                    child: Text('$emoji $label'),
                                  );
                                }).toList(),
                              ],
                              // Manually added filters
                              if (_manualFilters.isNotEmpty) ...[
                                const DropdownMenuItem(
                                  enabled: false,
                                  value: '',
                                  child: Divider(height: 8),
                                ),
                                ..._manualFilters
                                    .where((goalType) => !_goals.any((g) => g.type == goalType))
                                    .map((goalType) {
                                  final emoji = _getGoalEmoji(goalType);
                                  final label = goalType[0].toUpperCase() + goalType.substring(1);
                                  return DropdownMenuItem(
                                    value: 'goal_type_$goalType',
                                    child: Row(
                                      children: [
                                        Text('$emoji $label (no goal)'),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                              // Add new filter option
                              if (_goals.isNotEmpty || _manualFilters.isNotEmpty) ...[
                                const DropdownMenuItem(
                                  enabled: false,
                                  value: '',
                                  child: Divider(height: 8),
                                ),
                              ],
                              DropdownMenuItem(
                                value: 'add_filter',
                                child: Row(
                                  children: [
                                    const Icon(Icons.add, size: 14),
                                    const SizedBox(width: 6),
                                    const Text('Add category'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value == 'add_filter') {
                                _showAddFilterDialog();
                              } else if (value != null && value.isNotEmpty) {
                                setState(() {
                                  _selectedFilter = value;
                                });
                              }
                            },
                          ),
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
                        bool isFertile = _isFertileWindow(day);

                        // Check if goal is completed on this day
                        bool isGoalCompleted = false;
                        if (_selectedFilter.startsWith('goal_type_')) {
                          final goalType = _selectedFilter.replaceFirst('goal_type_', '');
                          final goalsOfType = _goals.where((g) => g.type == goalType).toList();
                          final dateKey = DateTime(day.year, day.month, day.day);
                          
                          for (final goal in goalsOfType) {
                            if (_goalCompletions[goal.id]?[dateKey] ?? false) {
                              isGoalCompleted = true;
                              break;
                            }
                          }
                        }

                        return Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getFilteredDayColor(day),
                              border: isToday ? Border.all(color: Colors.blue, width: 2) : 
                                     isFertile ? Border.all(color: Colors.green, width: 1.5) : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Goal overlays (borders) - shown in phase view
                                if (_selectedFilter == 'phases')
                                  ..._buildGoalOverlayBorders(day),
                                
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
                                // Completion marker for goal filters
                                if (_selectedFilter.startsWith('goal_type_')) ...[
                                  if (isGoalCompleted)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      size: 14,
                                    ),
                                ] else
                                  // Day number for phase view
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
                      // Progress section for goal type filters
                      if (_selectedFilter.startsWith('goal_type_')) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: _buildGoalTypeProgressSection(),
                        ),
                        // Weekly Summary Card (Always visible, compact)
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: _buildWeeklySummaryCard(),
                        ),
                        // Monthly Summary Card (Collapsible)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showMonthlySummary = !_showMonthlySummary;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Monthly Summary',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Icon(
                                          _showMonthlySummary
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: Colors.grey.shade600,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_showMonthlySummary) ...[
                                  const Divider(height: 0),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: _buildMonthlySummaryCard(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
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
    // Use the new phase ranges with updated boundaries:
    // - Menstrual: Day 1–periodLength
    // - Follicular: Day (periodLength+1)–(ovulationDay-2)
    // - Ovulation: Day (ovulationDay-1)–(ovulationDay+1)
    // - Early Luteal: Day (ovulationDay+2)–(ovulationDay+5)
    // - Luteal: Day (ovulationDay+6)–cycleLength
    final ovulationDay = _cycleLength - 14;
    
    Map<String, String> ranges = {
      'Menstrual': 'Days 1–$_menstrualLength',
      'Follicular': 'Days ${_menstrualLength + 1}–${ovulationDay - 2}',
      'Ovulation': 'Days ${ovulationDay - 1}–${ovulationDay + 1}',
      'Early Luteal': 'Days ${ovulationDay + 2}–${ovulationDay + 5}',
      'Luteal': 'Days ${ovulationDay + 6}–$_cycleLength',
    };
    
    return ranges[currentPhase] ?? 'Day $_cycleLength - last cycle day';
  }
}

/// Modal popup for day details with lifestyle recommendations
class DayDetailsModal extends StatefulWidget {
  final DateTime date;
  final String phase;
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int menstrualLength;
  final List<Goal> filteredGoals;
  final Map<String, Map<DateTime, bool>> goalCompletions;
  final Function(String, DateTime, bool) onGoalCompletionChanged;
  final Map<String, dynamic> progressMetrics;
  final String noGoalMessage;

  const DayDetailsModal({
    super.key,
    required this.date,
    required this.phase,
    required this.lastPeriodStart,
    required this.cycleLength,
    required this.menstrualLength,
    this.filteredGoals = const [],
    required this.goalCompletions,
    required this.onGoalCompletionChanged,
    this.progressMetrics = const {},
    this.noGoalMessage = '',
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
  late Map<String, dynamic> _currentProgressMetrics;
  
  // Collapsible panels state
  bool _expandedPhaseSummary = false;
  bool _expandedHighlights = false;
  bool _expandedQuickLog = false;

  @override
  void initState() {
    super.initState();
    _phaseData = CyclePhases.findPhaseByName(widget.phase);
    _currentProgressMetrics = widget.progressMetrics;
    _loadUserPreferences();
    _loadSymptomsAndNotes();
  }

  void _updateProgressMetrics() {
    // Recalculate progress based on current goal completion state
    if (widget.filteredGoals.isNotEmpty) {
      _currentProgressMetrics = _calculateGoalProgress();
    }
  }

  String _getNextPeriodDateFormatted() {
    final nextPeriodDate = getNextPeriodDate(widget.lastPeriodStart, widget.cycleLength);
    return '${nextPeriodDate.month}/${nextPeriodDate.day}';
  }

  Map<String, dynamic> _calculateGoalProgress() {
    final goalsOfType = widget.filteredGoals;
    if (goalsOfType.isEmpty) {
      return {'completed': 0, 'total': 0, 'percentage': 0, 'message': 'No goals set'};
    }

    final isFrequencyGoal = goalsOfType.every((g) => 
      g.type == 'Exercise' || g.type == 'Meditation' || g.type == 'Wellness');
    
    if (isFrequencyGoal && goalsOfType.any((g) => 
      g.type == 'Exercise' || g.type == 'Meditation' || g.type == 'Wellness')) {
      // Frequency goals
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      int totalCompleted = 0;
      int totalTarget = 0;

      for (final goal in goalsOfType) {
        final frequency = int.tryParse(goal.frequency) ?? 1;
        totalTarget += frequency;

        final daysCompleted = <DateTime>{};
        for (int i = 0; i < 7; i++) {
          final checkDate = weekStart.add(Duration(days: i));
          final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
          if (widget.goalCompletions[goal.id]?[dateKey] ?? false) {
            daysCompleted.add(dateKey);
          }
        }
        totalCompleted += daysCompleted.length;
      }

      return {
        'completed': totalCompleted,
        'total': totalTarget,
        'percentage': totalTarget > 0 ? (totalCompleted / totalTarget * 100).toStringAsFixed(0) : 0,
        'message': '$totalCompleted/$totalTarget times completed this week',
        'timeframe': 'week'
      };
    } else {
      // Daily goals
      final now = DateTime.now();
      int monthCompleted = 0;
      int daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      for (final goal in goalsOfType) {
        for (int day = 1; day <= daysInMonth; day++) {
          final checkDate = DateTime(now.year, now.month, day);
          final dateKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
          if (widget.goalCompletions[goal.id]?[dateKey] ?? false) {
            monthCompleted++;
            break;
          }
        }
      }

      return {
        'completed': monthCompleted,
        'total': daysInMonth,
        'percentage': (monthCompleted / daysInMonth * 100).toStringAsFixed(0),
        'message': '$monthCompleted/$daysInMonth days completed this month',
        'timeframe': 'month'
      };
    }
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

    // Get recommendations from phase data
    final lifestylePhase = _phaseData?.lifestylePhase ?? 'Balanced';
    final workoutType = _phaseData?.workoutType ?? '💪';
    final dietType = _phaseData?.dietType ?? 'Balanced';
    final fastingDuration = _phaseData?.fastingDuration ?? 'No fasting';
    final guidanceNotes = _phaseData?.guidanceNotes ?? 'No specific recommendations';
    final workoutEmoji = _phaseData?.workoutEmoji ?? '🏋️';
    final nutritionEmoji = _phaseData?.nutritionEmoji ?? '🍽️';

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
            // Header with close button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cycle Day Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 24),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Cycle Day & Phase
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _phaseData?.emoji ?? '🌙',
                            style: const TextStyle(fontSize: 40),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cycle Day $dayOfCycle',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                Text(
                                  widget.phase,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2. Workout Recommendation
                    _buildRecommendationCard(
                      title: 'Workout',
                      emoji: workoutEmoji,
                      recommendation: workoutType,
                      backgroundColor: Colors.blue.shade50,
                      borderColor: Colors.blue.shade200,
                    ),

                    const SizedBox(height: 16),

                    // 3. Diet Recommendation
                    _buildRecommendationCard(
                      title: 'Diet',
                      emoji: nutritionEmoji,
                      recommendation: dietType,
                      backgroundColor: Colors.green.shade50,
                      borderColor: Colors.green.shade200,
                    ),

                    const SizedBox(height: 16),

                    // 4. Fasting Recommendation
                    _buildRecommendationCard(
                      title: 'Fasting',
                      emoji: '⏱️',
                      recommendation: fastingDuration,
                      backgroundColor: Colors.orange.shade50,
                      borderColor: Colors.orange.shade200,
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

  Widget _buildRecommendationCard({
    required String title,
    required String emoji,
    required String recommendation,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF555555),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDataTile({
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
        ? (_phaseData?.dietType ?? 'Balanced Nutrition')
        : _selectedMeals.entries
            .map((e) => '${e.key.capitalize()}: ${e.value}')
            .join('\n');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NutritionMealsScreen(
              dietType: _phaseData?.dietType ?? 'Balanced Nutrition',
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
        ? (_phaseData?.workoutType ?? 'Moderate exercise')
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
        ? (_phaseData?.fastingDuration ?? 'No Fasting')
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

  // Collapsible Panel: Phase Summary with Complete Guidance
  Widget _buildPhaseSummaryPanel() {
    Map<String, String> guidance = getPhaseGuidance(widget.phase);
    String hormonal = guidance['hormonal'] ?? '';
    String workout = guidance['workout'] ?? '';
    String nutrition = guidance['nutrition'] ?? '';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: getPhaseColor(widget.phase).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: getPhaseColor(widget.phase).withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: _expandedPhaseSummary,
        onExpansionChanged: (expanded) {
          setState(() => _expandedPhaseSummary = expanded);
        },
        title: const Text(
          'Phase Summary & Guidance',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hormonal Basis
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hormonal State',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hormonal,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Workout & Nutrition Guidance
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  getWorkoutPhaseEmoji(workout),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Workout',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        workout,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  getNutritionPhaseEmoji(nutrition),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nutrition',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        nutrition,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF333333),
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
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Phase Characteristics
                if (_phaseData != null) ...[
                  Text(
                    'Characteristics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _phaseData!.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF333333),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Collapsible Panel: Upcoming Highlights
  Widget _buildUpcomingHighlightsPanel() {
    // Show upcoming days in the phase
    int dayOfCycle = (widget.date.difference(widget.lastPeriodStart).inDays %
            widget.cycleLength) +
        1;
    
    // Calculate phase end day based on current phase using new boundaries:
    // - Menstrual: Day 1–periodLength
    // - Follicular: Day (periodLength+1)–(ovulationDay-2)
    // - Ovulation: Day (ovulationDay-1)–(ovulationDay+1)
    // - Early Luteal: Day (ovulationDay+2)–(ovulationDay+5)
    // - Luteal: Day (ovulationDay+6)–cycleLength
    int phaseEndDay = widget.cycleLength;
    String currentPhase = getCyclePhase(widget.lastPeriodStart, widget.cycleLength, widget.date,
        menstrualLength: widget.menstrualLength);
    final ovulationDay = widget.cycleLength - 14;
    
    switch (currentPhase) {
      case 'Menstrual':
        phaseEndDay = widget.menstrualLength;
        break;
      case 'Follicular':
        phaseEndDay = ovulationDay - 2;
        break;
      case 'Ovulation':
        phaseEndDay = ovulationDay + 1;
        break;
      case 'Early Luteal':
        phaseEndDay = ovulationDay + 5;
        break;
      case 'Luteal':
        phaseEndDay = widget.cycleLength;
        break;
    }
    
    int daysUntilPhaseChange = phaseEndDay - dayOfCycle + 1;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: _expandedHighlights,
        onExpansionChanged: (expanded) {
          setState(() => _expandedHighlights = expanded);
        },
        title: const Text(
          'Upcoming Highlights',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Days until phase change',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$daysUntilPhaseChange days',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Phase',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_phaseData?.nextPhase != null)
                            Text(
                              _phaseData!.nextPhase!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next Period',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getNextPeriodDateFormatted(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
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
        ],
      ),
    );
  }

  // Collapsible Panel: Quick Log
  Widget _buildQuickLogPanel() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: _expandedQuickLog,
        onExpansionChanged: (expanded) {
          setState(() => _expandedQuickLog = expanded);
        },
        title: const Text(
          'Quick Log',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showSymptomsAndNotes,
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Log Symptoms & Notes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFitnessSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FitnessSuggestionsScreen(
          workoutType: _phaseData?.workoutType ?? 'Fitness',
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
          fastingType: _phaseData?.fastingDuration ?? 'No Fasting',
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


class AchievementCelebrationDialog extends StatefulWidget {
  final VoidCallback onClose;

  const AchievementCelebrationDialog({
    super.key,
    required this.onClose,
  });

  @override
  State<AchievementCelebrationDialog> createState() => _AchievementCelebrationDialogState();
}

class _AchievementCelebrationDialogState extends State<AchievementCelebrationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late Animation<Offset> _slideAnimation;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _badgeScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.elasticOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeOut),
    );

    // Start animations
    _badgeController.forward();
    _generateParticles();

    // Auto-close after 4 seconds
    Future.delayed(const Duration(seconds: 4), widget.onClose);
  }

  void _generateParticles() {
    // Generate floating emojis
    final emojis = ['🎉', '✨', '⭐', '🌟', '💫'];
    for (int i = 0; i < 30; i++) {
      _particles.add(
        _Particle(
          emoji: emojis[i % emojis.length],
          initialX: (i % 6) * 60.0,
          initialY: 0,
          duration: Duration(milliseconds: 2000 + (i % 5) * 200),
        ),
      );
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Floating particles (emojis)
        ..._particles.map((particle) => _ParticleWidget(particle: particle)),

        // Dialog
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _badgeScale,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.pink.shade200.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Trophy Emoji - Large with spin
                    RotationTransition(
                      turns: Tween(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
                      ),
                      child: const Text(
                        '🏆',
                        style: TextStyle(fontSize: 80),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    const Text(
                      'Amazing Work!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'You completed all your goals today!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Badge - Minimalist
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber.shade300, width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '⭐',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Daily Achiever',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '⭐',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Motivational message
                    const Text(
                      'Keep this momentum going!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Particle {
  final String emoji;
  final double initialX;
  final double initialY;
  final Duration duration;

  _Particle({
    required this.emoji,
    required this.initialX,
    required this.initialY,
    required this.duration,
  });
}

class _ParticleWidget extends StatefulWidget {
  final _Particle particle;

  const _ParticleWidget({required this.particle});

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.particle.duration,
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset(widget.particle.initialX, widget.particle.initialY),
      end: Offset(
        widget.particle.initialX + (80 * (2 * (widget.particle.initialX / 360) - 1)),
        widget.particle.initialY - 300,
      ),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _offsetAnimation.value.dx,
          top: MediaQuery.of(context).size.height * 0.5 + _offsetAnimation.value.dy,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Text(
              widget.particle.emoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
        );
      },
    );
  }
}

extension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
