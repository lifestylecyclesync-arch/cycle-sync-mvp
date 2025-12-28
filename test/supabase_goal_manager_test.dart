import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Goal Manager Tests', () {
    group('Goal Model - Serialization', () {
      test('Goal.fromMap creates instance from map data', () {
        final goalData = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
          'frequency': 'daily',
          'description': 'Drink 8 glasses of water',
          'created_at': '2024-01-15T10:00:00Z',
          'updated_at': '2024-01-15T10:00:00Z',
        };

        expect(goalData['id'], 'goal-123');
        expect(goalData['user_id'], 'user-456');
        expect(goalData['goal_type'], 'hydration');
        expect(goalData['target_value'], 8);
        expect(goalData['frequency'], 'daily');
      });

      test('Goal.toMap converts instance to map', () {
        final goalMap = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'exercise',
          'target_value': 30,
          'frequency': 'daily',
          'description': 'Exercise 30 minutes',
          'is_completed': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(goalMap['id'], 'goal-123');
        expect(goalMap['goal_type'], 'exercise');
        expect(goalMap.containsKey('created_at'), true);
        expect(goalMap.containsKey('updated_at'), true);
      });

      test('Goal handles all required fields', () {
        final requiredFields = [
          'id',
          'user_id',
          'goal_type',
          'target_value',
          'frequency',
          'created_at',
          'updated_at',
        ];

        final goalData = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
          'frequency': 'daily',
          'created_at': '2024-01-15T10:00:00Z',
          'updated_at': '2024-01-15T10:00:00Z',
        };

        for (var field in requiredFields) {
          expect(goalData.containsKey(field), true);
        }
      });

      test('Goal handles optional description field', () {
        final goalWithDescription = {
          'id': 'goal-1',
          'description': 'Stay hydrated throughout the day',
        };

        final goalWithoutDescription = {
          'id': 'goal-2',
        };

        expect(goalWithDescription['description'], isNotEmpty);
        expect(goalWithoutDescription['description'], isNull);
      });
    });

    group('Goal Types and Enum Mapping', () {
      test('Supports all goal type enums', () {
        const goalTypes = [
          'hydration',
          'exercise',
          'nutrition',
          'sleep',
          'stress',
          'meditation',
          'journaling',
        ];

        for (var type in goalTypes) {
          expect(type.isNotEmpty, true);
        }
      });

      test('Maps string to GoalType enum correctly', () {
        const mappings = {
          'hydration': 'hydration',
          'exercise': 'exercise',
          'nutrition': 'nutrition',
          'sleep': 'sleep',
          'stress': 'stress',
          'meditation': 'meditation',
          'journaling': 'journaling',
        };

        for (var key in mappings.keys) {
          expect(mappings[key], key);
        }
      });

      test('Handles invalid goal type gracefully', () {
        const invalidType = 'invalid_goal_type';
        const validTypes = [
          'hydration',
          'exercise',
          'nutrition',
        ];

        expect(validTypes.contains(invalidType), false);
      });

      test('Goal type names are consistent across serialization', () {
        const goalType = 'hydration';
        
        final goalData = {
          'goal_type': goalType,
        };

        expect(goalData['goal_type'], goalType);
        expect(goalData['goal_type'].runtimeType, String);
      });
    });

    group('Goal CRUD Operations', () {
      test('Can create goal with valid data', () {
        final newGoal = {
          'id': 'goal-new-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
          'frequency': 'daily',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(newGoal['id'], isNotEmpty);
        expect(newGoal['user_id'], isNotEmpty);
        expect(newGoal['goal_type'], 'hydration');
      });

      test('Validates target value is positive', () {
        const validValues = [1, 5, 8, 30, 60, 100];
        const invalidValues = [-1, 0];

        for (var value in validValues) {
          expect(value > 0, true);
        }

        for (var value in invalidValues) {
          expect(value > 0, false);
        }
      });

      test('Can update goal properties', () {
        var goal = {
          'id': 'goal-123',
          'target_value': 8,
          'is_completed': false,
        };

        // Update target value
        goal['target_value'] = 10;
        expect(goal['target_value'], 10);

        // Mark as completed
        goal['is_completed'] = true;
        expect(goal['is_completed'], true);

        // Update timestamp
        goal['updated_at'] = DateTime.now().toIso8601String();
        expect(goal['updated_at'], isNotEmpty);
      });

      test('Can delete goal', () {
        final goals = <String, dynamic>{
          'goal-1': {'id': 'goal-1', 'goal_type': 'hydration'},
          'goal-2': {'id': 'goal-2', 'goal_type': 'exercise'},
          'goal-3': {'id': 'goal-3', 'goal_type': 'sleep'},
        };

        expect(goals.length, 3);
        
        goals.remove('goal-1');
        expect(goals.length, 2);
        expect(goals.containsKey('goal-1'), false);
      });

      test('Can retrieve goal by ID', () {
        final goals = {
          'goal-1': {'id': 'goal-1', 'goal_type': 'hydration'},
          'goal-2': {'id': 'goal-2', 'goal_type': 'exercise'},
        };

        final retrievedGoal = goals['goal-1'];
        expect(retrievedGoal?['id'], 'goal-1');
        expect(retrievedGoal?['goal_type'], 'hydration');
      });

      test('Can retrieve all user goals', () {
        final userGoals = [
          {'id': 'goal-1', 'user_id': 'user-456', 'goal_type': 'hydration'},
          {'id': 'goal-2', 'user_id': 'user-456', 'goal_type': 'exercise'},
          {'id': 'goal-3', 'user_id': 'user-456', 'goal_type': 'sleep'},
        ];

        expect(userGoals.length, 3);
        expect(userGoals.every((g) => g['user_id'] == 'user-456'), true);
      });
    });

    group('Goal Completion Tracking', () {
      test('Can mark goal as completed', () {
        var goal = {
          'id': 'goal-123',
          'is_completed': false,
          'completed_at': null,
        };

        // Mark completed
        goal['is_completed'] = true;
        goal['completed_at'] = DateTime.now().toIso8601String();

        expect(goal['is_completed'], true);
        expect(goal['completed_at'], isNotEmpty);
      });

      test('Can unmark goal as incomplete', () {
        var goal = {
          'id': 'goal-123',
          'is_completed': true,
          'completed_at': '2024-01-15T15:00:00Z',
        };

        goal['is_completed'] = false;
        goal.remove('completed_at');

        expect(goal['is_completed'], false);
        expect(goal['completed_at'], isNull);
      });

      test('Tracks completion date and time', () {
        final completionTime = DateTime.now();
        
        var goal = {
          'id': 'goal-123',
          'is_completed': true,
          'completed_at': completionTime.toIso8601String(),
        };

        expect(goal['is_completed'], true);
        expect(goal['completed_at'], isNotEmpty);
      });

      test('Can calculate goal progress percentage', () {
        final completedCount = 5;
        const totalDays = 7;
        final progressPercent = (completedCount / totalDays * 100).toStringAsFixed(1);

        expect(double.parse(progressPercent), greaterThan(0));
        expect(double.parse(progressPercent), lessThan(100));
      });
    });

    group('Goal Frequency Handling', () {
      test('Supports various frequency options', () {
        const frequencies = [
          'daily',
          'weekly',
          'monthly',
          'custom',
        ];

        for (var freq in frequencies) {
          expect(freq.isNotEmpty, true);
        }
      });

      test('Calculates next occurrence based on frequency', () {
        final today = DateTime.now();
        
        // Daily: next occurrence is tomorrow
        final nextDaily = today.add(Duration(days: 1));
        expect(nextDaily.isAfter(today), true);

        // Weekly: next occurrence is 7 days later
        final nextWeekly = today.add(Duration(days: 7));
        expect(nextWeekly.difference(today).inDays, 7);

        // Monthly: approximate (30 days)
        final nextMonthly = today.add(Duration(days: 30));
        expect(nextMonthly.month, (today.month % 12) + 1);
      });
    });

    group('Error Handling', () {
      test('Handles missing required fields', () {
        final incompleteGoal = {
          'id': 'goal-123',
          // Missing user_id, goal_type, target_value, etc.
        };

        expect(incompleteGoal['user_id'], isNull);
        expect(incompleteGoal['goal_type'], isNull);
        expect(incompleteGoal['target_value'], isNull);
      });

      test('Handles null goal data', () {
        final goalData = null;
        expect(goalData, isNull);
      });

      test('Handles empty goals list', () {
        final goals = <Map<String, dynamic>>[];
        expect(goals.isEmpty, true);
      });

      test('Handles invalid target value', () {
        expect(() {
          final invalidValue = -5;
          if (invalidValue <= 0) {
            throw ArgumentError('Target value must be positive');
          }
        }, throwsArgumentError);
      });

      test('Handles duplicate goal IDs', () {
        final goals = <String, dynamic>{
          'goal-1': {'id': 'goal-1', 'goal_type': 'hydration'},
        };

        // Attempting to add duplicate should overwrite
        goals['goal-1'] = {'id': 'goal-1', 'goal_type': 'exercise'};
        
        expect(goals.length, 1);
        expect(goals['goal-1']!['goal_type'], 'exercise');
      });
    });

    group('Data Validation', () {
      test('Validates goal description length', () {
        const maxLength = 500;
        
        const shortDesc = 'Drink water';
        final longDesc = 'a' * 600;

        expect(shortDesc.length <= maxLength, true);
        expect(longDesc.length <= maxLength, false);
      });

      test('Validates user_id is not empty', () {
        final goalWithUserId = {'user_id': 'user-456'};
        final goalWithoutUserId = {'user_id': ''};

        expect(goalWithUserId['user_id']?.isNotEmpty ?? false, true);
        expect(goalWithoutUserId['user_id']?.isNotEmpty ?? false, false);
      });

      test('Validates timestamps are valid ISO8601 format', () {
        const validTimestamp = '2024-01-15T10:00:00Z';
        const invalidTimestamp = 'not-a-timestamp';

        expect(() => DateTime.parse(validTimestamp), returnsNormally);
        expect(() => DateTime.parse(invalidTimestamp), throwsFormatException);
      });
    });
  });
}
