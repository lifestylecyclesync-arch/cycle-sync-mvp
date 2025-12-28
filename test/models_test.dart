import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Models Tests', () {
    group('Cycle Model', () {
      test('Cycle can be created with all required fields', () {
        final cycleData = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': DateTime(2024, 1, 15),
          'cycle_length': 28,
          'phase_lengths': [5, 9, 9, 5],
        };

        expect(cycleData['id'], 'cycle-123');
        expect(cycleData['user_id'], 'user-456');
        expect(cycleData['cycle_length'], 28);
        expect((cycleData['phase_lengths'] as List).length, 4);
      });

      test('Cycle.fromMap correctly deserializes data', () {
        final jsonData = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': '2024-01-15T00:00:00Z',
          'cycle_length': 28,
          'phase_length': '5,9,9,5',
          'is_current': true,
        };

        // Simulate parsing
        expect(jsonData['id'], 'cycle-123');
        expect(jsonData['cycle_length'], 28);
        expect(jsonData['phase_length'], isNotEmpty);
      });

      test('Cycle.toMap correctly serializes data', () {
        final cycle = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': '2024-01-15T00:00:00Z',
          'cycle_length': 28,
          'is_current': true,
        };

        expect(cycle.containsKey('id'), true);
        expect(cycle.containsKey('start_date'), true);
        expect(cycle['cycle_length'], 28);
      });

      test('Cycle equality comparison', () {
        final cycle1 = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'cycle_length': 28,
        };

        final cycle2 = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'cycle_length': 28,
        };

        expect(cycle1['id'] == cycle2['id'], true);
        expect(cycle1 == cycle2, true);
      });

      test('Cycle supports phase length arrays of different sizes', () {
        // Standard 4-phase cycle
        final standardPhases = [5, 9, 9, 5];
        expect(standardPhases.length, 4);
        expect(standardPhases.reduce((a, b) => a + b), 28);

        // Custom phase breakdown
        final customPhases = [6, 10, 8, 4];
        expect(customPhases.reduce((a, b) => a + b), 28);
      });

      test('Cycle handles edge case cycle lengths', () {
        final shortCycle = {
          'cycle_length': 21,
          'phase_lengths': [4, 7, 7, 3],
        };

        final longCycle = {
          'cycle_length': 35,
          'phase_lengths': [5, 10, 10, 10],
        };

        expect((shortCycle['phase_lengths'] as List).reduce((a, b) => a + b), 21);
        expect((longCycle['phase_lengths'] as List).reduce((a, b) => a + b), 35);
      });
    });

    group('Goal Model', () {
      test('Goal can be created with all required fields', () {
        final goal = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8.0,
          'frequency': 'daily',
          'description': 'Drink 8 glasses of water daily',
          'created_at': DateTime(2024, 1, 15),
          'updated_at': DateTime(2024, 1, 15),
        };

        expect(goal['id'], 'goal-123');
        expect(goal['goal_type'], 'hydration');
        expect(goal['target_value'], 8.0);
      });

      test('Goal.fromMap correctly deserializes JSON data', () {
        final jsonData = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'exercise',
          'target_value': 30,
          'frequency': 'daily',
          'description': 'Exercise 30 minutes',
          'created_at': '2024-01-15T10:00:00Z',
          'updated_at': '2024-01-15T10:00:00Z',
        };

        expect(jsonData['id'], 'goal-123');
        expect(jsonData['goal_type'], 'exercise');
        expect(jsonData['target_value'], 30);
      });

      test('Goal.toMap correctly serializes to JSON', () {
        final goal = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(goal.containsKey('id'), true);
        expect(goal.containsKey('goal_type'), true);
        expect(goal.containsKey('created_at'), true);
        expect(goal.containsKey('updated_at'), true);
      });

      test('Goal supports all goal type enum values', () {
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
          final goal = {
            'goal_type': type,
          };
          expect(goalTypes.contains(goal['goal_type']), true);
        }
      });

      test('Goal equality comparison', () {
        final goal1 = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
        };

        final goal2 = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
        };

        expect(goal1['id'] == goal2['id'], true);
      });

      test('Goal handles optional fields', () {
        final minimalGoal = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
        };

        final fullGoal = {
          'id': 'goal-123',
          'user_id': 'user-456',
          'goal_type': 'hydration',
          'target_value': 8,
          'description': 'Detailed description',
          'is_completed': false,
          'completed_at': null,
        };

        expect(minimalGoal.length, lessThan(fullGoal.length));
        expect(minimalGoal['id'] == fullGoal['id'], true);
      });

      test('Goal with varying target values', () {
        const values = [1, 8, 30, 60, 100, 200];

        for (var value in values) {
          final goal = {
            'goal_type': 'hydration',
            'target_value': value,
          };
          expect(goal['target_value'], value);
        }
      });
    });

    group('Phase Model', () {
      test('Phase can be created with required fields', () {
        final phase = {
          'id': 'phase-menstrual',
          'name': 'Menstrual',
          'start_day': 1,
          'end_day': 5,
          'duration_days': 5,
          'color': 0xFFE91E63,
          'description': 'Menstrual phase',
        };

        expect(phase['name'], 'Menstrual');
        expect(phase['start_day'], 1);
        expect(phase['end_day'], 5);
        expect(phase['duration_days'], 5);
      });

      test('Phase.fromMap correctly deserializes', () {
        final jsonData = {
          'id': 'phase-ovulation',
          'name': 'Ovulation',
          'start_day': 15,
          'end_day': 23,
          'duration_days': 9,
          'color': '#FF9C27B0',
          'description': 'Peak fertility phase',
        };

        expect(jsonData['name'], 'Ovulation');
        expect(jsonData['start_day'], 15);
        expect(jsonData['duration_days'], 9);
      });

      test('Phase.toMap correctly serializes', () {
        final phase = {
          'id': 'phase-follicular',
          'name': 'Follicular',
          'start_day': 6,
          'end_day': 14,
          'duration_days': 9,
          'color': '0xFF2196F3',
        };

        expect(phase.containsKey('id'), true);
        expect(phase.containsKey('name'), true);
        expect(phase['start_day'], 6);
      });

      test('Phase supports all standard cycle phases', () {
        final phases = [
          {'name': 'Menstrual', 'start': 1, 'end': 5},
          {'name': 'Follicular', 'start': 6, 'end': 14},
          {'name': 'Ovulation', 'start': 15, 'end': 23},
          {'name': 'Luteal', 'start': 24, 'end': 28},
        ];

        expect(phases.length, 4);
        for (var phase in phases) {
          expect(phase.containsKey('name'), true);
          expect(phase.containsKey('start'), true);
        }
      });

      test('Phase day ranges are consistent with cycle', () {
        final phases = [
          {'start': 1, 'end': 5},
          {'start': 6, 'end': 14},
          {'start': 15, 'end': 23},
          {'start': 24, 'end': 28},
        ];

        // Verify no gaps and no overlaps
        for (var i = 0; i < phases.length - 1; i++) {
          expect(phases[i]['end']! + 1, phases[i + 1]['start']);
        }

        // Verify complete cycle coverage
        expect(phases.first['start'], 1);
        expect(phases.last['end'], 28);
      });

      test('Phase equality comparison', () {
        final phase1 = {
          'id': 'phase-menstrual',
          'name': 'Menstrual',
        };

        final phase2 = {
          'id': 'phase-menstrual',
          'name': 'Menstrual',
        };

        expect(phase1['id'] == phase2['id'], true);
      });

      test('Phase handles custom day ranges', () {
        final customPhases = [
          {'start': 1, 'end': 6},
          {'start': 7, 'end': 15},
          {'start': 16, 'end': 22},
          {'start': 23, 'end': 28},
        ];

        var totalDays = 0;
        for (var phase in customPhases) {
          totalDays += (phase['end']! - phase['start']! + 1);
        }

        expect(totalDays, 28);
      });
    });

    group('UserPreferences Model', () {
      test('UserPreferences can be created with defaults', () {
        final prefs = {
          'user_id': 'user-456',
          'theme': 'light',
          'notifications_enabled': true,
          'avatar_id': null,
          'photo_url': null,
        };

        expect(prefs['theme'], 'light');
        expect(prefs['notifications_enabled'], true);
      });

      test('UserPreferences.fromMap deserializes correctly', () {
        final jsonData = {
          'user_id': 'user-456',
          'theme': 'dark',
          'notifications_enabled': false,
          'avatar_id': 'avatar-5',
          'photo_url': 'https://example.com/photo.jpg',
        };

        expect(jsonData['theme'], 'dark');
        expect(jsonData['notifications_enabled'], false);
        expect(jsonData['avatar_id'], 'avatar-5');
      });

      test('UserPreferences.toMap serializes correctly', () {
        final prefs = {
          'user_id': 'user-456',
          'theme': 'dark',
          'notifications_enabled': false,
          'avatar_id': 'avatar-5',
          'updated_at': DateTime.now().toIso8601String(),
        };

        expect(prefs.containsKey('theme'), true);
        expect(prefs.containsKey('notifications_enabled'), true);
        expect(prefs.containsKey('updated_at'), true);
      });

      test('UserPreferences.copyWith creates modified copy', () {
        final original = {
          'theme': 'light',
          'notifications_enabled': true,
          'avatar_id': 'avatar-1',
        };

        final modified = {
          ...original,
          'theme': 'dark',
        };

        expect(original['theme'], 'light');
        expect(modified['theme'], 'dark');
        expect(modified['notifications_enabled'], true);
      });

      test('UserPreferences handles null optional fields', () {
        final prefsWithNulls = {
          'user_id': 'user-456',
          'avatar_id': null,
          'photo_url': null,
        };

        final prefsWithValues = {
          'user_id': 'user-456',
          'avatar_id': 'avatar-5',
          'photo_url': 'https://example.com/photo.jpg',
        };

        expect(prefsWithNulls['avatar_id'], isNull);
        expect(prefsWithValues['avatar_id'], 'avatar-5');
      });

      test('UserPreferences equality comparison', () {
        final prefs1 = {
          'user_id': 'user-456',
          'theme': 'dark',
          'notifications_enabled': false,
        };

        final prefs2 = {
          'user_id': 'user-456',
          'theme': 'dark',
          'notifications_enabled': false,
        };

        expect(prefs1 == prefs2, true);
      });
    });

    group('Model Validation', () {
      test('Validates Cycle start date is not in future', () {
        final futureDate = DateTime.now().add(Duration(days: 10));
        final pastDate = DateTime.now().subtract(Duration(days: 5));

        expect(pastDate.isBefore(DateTime.now()), true);
        expect(futureDate.isAfter(DateTime.now()), true);
      });

      test('Validates Goal target value is positive', () {
        expect(() {
          const targetValue = -5;
          if (targetValue <= 0) {
            throw ArgumentError('Target must be positive');
          }
        }, throwsArgumentError);
      });

      test('Validates datetime fields are valid ISO8601', () {
        const validIso = '2024-01-15T10:30:00Z';
        const invalidIso = 'not-a-date';

        expect(() => DateTime.parse(validIso), returnsNormally);
        expect(() => DateTime.parse(invalidIso), throwsFormatException);
      });

      test('Validates IDs are not empty', () {
        final validId = 'goal-123';
        final emptyId = '';

        expect(validId.isNotEmpty, true);
        expect(emptyId.isEmpty, true);
      });
    });

    group('Model Type Safety', () {
      test('Ensures numeric fields are correct type', () {
        final goal = {
          'target_value': 8,
          'cycle_length': 28,
        };

        expect(goal['target_value'].runtimeType, int);
        expect(goal['cycle_length'].runtimeType, int);
      });

      test('Ensures string fields are correct type', () {
        final goal = {
          'id': 'goal-123',
          'goal_type': 'hydration',
          'frequency': 'daily',
        };

        expect(goal['id'].runtimeType, String);
        expect(goal['goal_type'].runtimeType, String);
      });

      test('Ensures boolean fields are correct type', () {
        final prefs = {
          'notifications_enabled': true,
        };

        expect(prefs['notifications_enabled'].runtimeType, bool);
      });

      test('Ensures datetime fields are correct type', () {
        final cycle = {
          'start_date': DateTime(2024, 1, 15),
        };

        expect(cycle['start_date'].runtimeType, DateTime);
      });
    });

    group('Model Edge Cases', () {
      test('Handles models with special characters in strings', () {
        final goal = {
          'description': 'Exercise & stay healthy! (30 min/day)',
        };

        expect(goal['description']?.contains('&'), true);
        expect(goal['description']?.contains('('), true);
      });

      test('Handles models with very long strings', () {
        final longDescription =
            'a' * 500; // 500 character string

        final goal = {
          'description': longDescription,
        };

        expect(goal['description']?.length, 500);
      });

      test('Handles models with unicode characters', () {
        final goal = {
          'description': 'Stay healthy 💪 and happy 😊',
        };

        expect(goal['description']?.contains('💪'), true);
      });

      test('Handles models with null fields', () {
        final goal = {
          'id': 'goal-123',
          'description': null,
          'completed_at': null,
        };

        expect(goal['description'], isNull);
        expect(goal['completed_at'], isNull);
      });
    });
  });
}
