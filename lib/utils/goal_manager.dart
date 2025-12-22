import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Goal {
  final String id;
  final String name;
  final String type; // 'exercise', 'water', 'sleep', 'meditation', 'nutrition', 'wellness'
  final String frequency; // 'daily', 'weekly', 'monthly'
  final int frequencyValue; // e.g., 3 (for 3 times per week)
  final String amount; // e.g., "3 times", "2 liters", "8 hours", "30 minutes"
  final String description; // e.g., "Yoga", "Running", "Strength training"
  final List<String> completedDates; // ISO dates when goal was completed

  Goal({
    required this.id,
    required this.name,
    required this.type,
    required this.frequency,
    required this.frequencyValue,
    required this.amount,
    required this.description,
    this.completedDates = const [],
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'frequency': frequency,
      'frequencyValue': frequencyValue,
      'amount': amount,
      'description': description,
      'completedDates': completedDates,
    };
  }

  // Create from JSON
  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      frequency: json['frequency'] as String,
      frequencyValue: json['frequencyValue'] as int,
      amount: json['amount'] as String,
      description: json['description'] as String,
      completedDates: List<String>.from(json['completedDates'] as List? ?? []),
    );
  }

  // Create a copy with updated completedDates
  Goal copyWith({
    List<String>? completedDates,
  }) {
    return Goal(
      id: id,
      name: name,
      type: type,
      frequency: frequency,
      frequencyValue: frequencyValue,
      amount: amount,
      description: description,
      completedDates: completedDates ?? this.completedDates,
    );
  }

  // Check if goal was completed today
  bool isCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return completedDates.contains(today);
  }

  // Mark goal as completed for today
  Goal markCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (completedDates.contains(today)) {
      return this;
    }
    return copyWith(completedDates: [...completedDates, today]);
  }

  // Unmark completion for today
  Goal markNotCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final updated = completedDates.where((date) => date != today).toList();
    return copyWith(completedDates: updated);
  }

  // Get display string (e.g., "3 times per week Yoga")
  String getDisplayString() {
    if (description.isNotEmpty) {
      return '$amount per $frequency $description';
    }
    return '$amount per $frequency';
  }
}

class GoalManager {
  static const String _goalsKey = 'user_goals';

  // Load all goals
  static Future<List<Goal>> getAllGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final goalsJson = prefs.getString(_goalsKey);
    
    if (goalsJson == null) return [];
    
    try {
      final decoded = jsonDecode(goalsJson) as List<dynamic>;
      return decoded.map((item) => Goal.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Save all goals
  static Future<void> saveAllGoals(List<Goal> goals) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(goals.map((g) => g.toJson()).toList());
    await prefs.setString(_goalsKey, encoded);
  }

  // Add a new goal
  static Future<void> addGoal(Goal goal) async {
    final goals = await getAllGoals();
    goals.add(goal);
    await saveAllGoals(goals);
  }

  // Update an existing goal
  static Future<void> updateGoal(Goal goal) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((g) => g.id == goal.id);
    if (index >= 0) {
      goals[index] = goal;
      await saveAllGoals(goals);
    }
  }

  // Delete a goal
  static Future<void> deleteGoal(String goalId) async {
    final goals = await getAllGoals();
    goals.removeWhere((g) => g.id == goalId);
    await saveAllGoals(goals);
  }

  // Mark goal as completed today
  static Future<void> markGoalCompletedToday(String goalId) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index >= 0) {
      goals[index] = goals[index].markCompletedToday();
      await saveAllGoals(goals);
    }
  }

  // Unmark goal completion for today
  static Future<void> markGoalNotCompletedToday(String goalId) async {
    final goals = await getAllGoals();
    final index = goals.indexWhere((g) => g.id == goalId);
    if (index >= 0) {
      goals[index] = goals[index].markNotCompletedToday();
      await saveAllGoals(goals);
    }
  }

  // Get goals by type
  static Future<List<Goal>> getGoalsByType(String type) async {
    final goals = await getAllGoals();
    return goals.where((g) => g.type == type).toList();
  }

  // Generate unique ID
  static String generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000)}';
  }
}
