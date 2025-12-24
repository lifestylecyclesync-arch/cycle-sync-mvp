import 'package:uuid/uuid.dart';
import 'supabase_service.dart';

enum GoalType { hydration, sleep, fitness, nutrition, meditation, wellness }

class Goal {
  final String id;
  final String userId;
  final GoalType goalType;
  final String targetValue;
  final String frequency;
  final String? description;
  final List<String> completedDates;
  final DateTime createdAt;
  final DateTime updatedAt;

  Goal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.targetValue,
    required this.frequency,
    this.description,
    this.completedDates = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType.toString().split('.').last,
      'target_value': targetValue,
      'frequency': frequency,
      'description': description,
      'completed_dates': completedDates,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      goalType: GoalType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['goal_type'] as String),
        orElse: () => GoalType.wellness,
      ),
      targetValue: map['target_value'] as String,
      frequency: map['frequency'] as String? ?? 'daily',
      description: map['description'] as String?,
      completedDates: List<String>.from(map['completed_dates'] as List? ?? []),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Goal copyWith({List<String>? completedDates}) {
    return Goal(
      id: id,
      userId: userId,
      goalType: goalType,
      targetValue: targetValue,
      frequency: frequency,
      description: description,
      completedDates: completedDates ?? this.completedDates,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool isCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return completedDates.contains(today);
  }

  Goal markCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    if (completedDates.contains(today)) return this;
    return copyWith(completedDates: [...completedDates, today]);
  }

  Goal markNotCompletedToday() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final updated = completedDates.where((date) => date != today).toList();
    return copyWith(completedDates: updated);
  }

  String getDisplayString() {
    return '$targetValue per $frequency';
  }
}

class SupabaseGoalManager {
  static const String _table = 'goals';

  // Get all goals for a user
  static Future<List<Goal>> getAllGoals(String userId) async {
    try {
      final data = await SupabaseService.fetchData(
        _table,
        userId: userId,
      );
      return data.map((item) => Goal.fromMap(item)).toList();
    } catch (e) {
      print('Error loading goals: $e');
      return [];
    }
  }

  // Get goals as a stream for real-time updates
  // TODO: Implement real-time stream when Supabase library is updated
  // static Stream<List<Goal>> getGoalsStream(String userId) {
  //   return SupabaseService.subscribeToTable(_table, userId: userId)
  //       .map((data) => data.map((item) => Goal.fromMap(item)).toList());
  // }

  // Add a new goal
  static Future<void> addGoal(Goal goal) async {
    try {
      await SupabaseService.insertData(_table, goal.toMap());
    } catch (e) {
      print('Error adding goal: $e');
    }
  }

  // Update an existing goal
  static Future<void> updateGoal(Goal goal) async {
    try {
      await SupabaseService.updateData(_table, goal.id, goal.toMap());
    } catch (e) {
      print('Error updating goal: $e');
    }
  }

  // Delete a goal
  static Future<void> deleteGoal(String goalId) async {
    try {
      await SupabaseService.deleteData(_table, goalId);
    } catch (e) {
      print('Error deleting goal: $e');
    }
  }

  // Mark goal as completed today
  static Future<void> markGoalCompletedToday(String goalId, Goal goal) async {
    try {
      final updated = goal.markCompletedToday();
      await updateGoal(updated);
    } catch (e) {
      print('Error marking goal as completed: $e');
    }
  }

  // Unmark goal completion for today
  static Future<void> markGoalNotCompletedToday(String goalId, Goal goal) async {
    try {
      final updated = goal.markNotCompletedToday();
      await updateGoal(updated);
    } catch (e) {
      print('Error unmarking goal: $e');
    }
  }

  // Get goals by type
  static Future<List<Goal>> getGoalsByType(String userId, GoalType type) async {
    try {
      final goals = await getAllGoals(userId);
      return goals.where((g) => g.goalType == type).toList();
    } catch (e) {
      print('Error getting goals by type: $e');
      return [];
    }
  }

  // Generate unique ID
  static String generateId() {
    return const Uuid().v4();
  }
}
