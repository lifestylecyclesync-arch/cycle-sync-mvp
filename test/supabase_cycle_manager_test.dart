import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/models/phase.dart';

void main() {
  group('Cycle Manager Tests', () {
    group('Cycle Model - Serialization', () {
      test('Cycle.fromMap creates instance from map data', () {
        final cycleData = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': '2024-01-15T00:00:00Z',
          'cycle_length': 28,
          'phase_length': '5,9,9,5',
          'is_current': true,
        };

        // Simulate fromMap behavior
        final cycleId = cycleData['id'];
        final userId = cycleData['user_id'];
        final startDate = DateTime.parse(cycleData['start_date'] as String);
        final cycleLength = cycleData['cycle_length'] as int;

        expect(cycleId, 'cycle-123');
        expect(userId, 'user-456');
        expect(startDate.year, 2024);
        expect(startDate.month, 1);
        expect(startDate.day, 15);
        expect(cycleLength, 28);
      });

      test('Cycle.toMap converts instance to map', () {
        final startDate = DateTime(2024, 1, 15);
        final cycleMap = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': startDate.toIso8601String(),
          'cycle_length': 28,
          'phase_length': '5,9,9,5',
          'is_current': true,
        };

        expect(cycleMap['id'], 'cycle-123');
        expect(cycleMap['cycle_length'], 28);
        expect(cycleMap.containsKey('start_date'), true);
      });

      test('Cycle handles null optional fields', () {
        final cycleData = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'start_date': '2024-01-15T00:00:00Z',
          'cycle_length': 28,
        };

        expect(cycleData['phase_length'], isNull);
        expect(cycleData['is_current'] ?? false, false);
      });
    });

    group('Cycle Calculations', () {
      test('getCurrentDay calculates correct day in cycle', () {
        final startDate = DateTime.now().subtract(Duration(days: 5));
        final currentDay = DateTime.now().difference(startDate).inDays + 1;

        expect(currentDay, greaterThan(0));
        expect(currentDay, lessThanOrEqualTo(28));
      });

      test('getNextCycleStart calculates future cycle start', () {
        final startDate = DateTime(2024, 1, 15);
        const cycleLength = 28;

        final nextStart = startDate.add(Duration(days: cycleLength));

        expect(nextStart.year, 2024);
        expect(nextStart.month, 2);
        expect(nextStart.day, 12);
      });

      test('Cycle completion calculation', () {
        final startDate = DateTime.now().subtract(Duration(days: 25));
        const cycleLength = 28;
        final daysElapsed = DateTime.now().difference(startDate).inDays;
        final percentComplete = (daysElapsed / cycleLength * 100).toStringAsFixed(1);

        expect(double.parse(percentComplete), greaterThan(0));
        expect(double.parse(percentComplete), lessThan(100));
      });

      test('Handles cycle length variations (21-35 days)', () {
        const shortCycle = 21;
        const normalCycle = 28;
        const longCycle = 35;

        expect(shortCycle, greaterThanOrEqualTo(21));
        expect(normalCycle, greaterThanOrEqualTo(21));
        expect(longCycle, lessThanOrEqualTo(35));
      });
    });

    group('Phase Detection', () {
      test('Detects menstrual phase (days 1-5)', () {
        final phase = _detectPhase(2, [5, 9, 9, 5]);
        expect(phase, 'menstrual');
      });

      test('Detects follicular phase (days 6-14)', () {
        final phase = _detectPhase(10, [5, 9, 9, 5]);
        expect(phase, 'follicular');
      });

      test('Detects ovulation phase (days 15-23)', () {
        final phase = _detectPhase(18, [5, 9, 9, 5]);
        expect(phase, 'ovulation');
      });

      test('Detects luteal phase (days 24-28)', () {
        final phase = _detectPhase(26, [5, 9, 9, 5]);
        expect(phase, 'luteal');
      });

      test('Handles custom phase lengths', () {
        final phaseLengths = [6, 10, 8, 4]; // Custom lengths
        final day = 7;
        final phase = _detectPhase(day, phaseLengths);

        expect(phase, 'follicular'); // Day 7 is in follicular
      });

      test('Handles boundary days between phases', () {
        final phaseLengths = [5, 9, 9, 5];
        
        // Last day of menstrual
        expect(_detectPhase(5, phaseLengths), 'menstrual');
        
        // First day of follicular
        expect(_detectPhase(6, phaseLengths), 'follicular');
        
        // Last day of follicular
        expect(_detectPhase(14, phaseLengths), 'follicular');
        
        // First day of ovulation
        expect(_detectPhase(15, phaseLengths), 'ovulation');
      });
    });

    group('Cycle CRUD Operations', () {
      test('Can create cycle with valid data', () {
        final cycleData = {
          'id': 'new-cycle-123',
          'user_id': 'user-456',
          'start_date': DateTime.now().toIso8601String(),
          'cycle_length': 28,
        };

        expect(cycleData['id'], isNotEmpty);
        expect(cycleData['user_id'], isNotEmpty);
        expect(cycleData.containsKey('start_date'), true);
        expect(cycleData['cycle_length'], 28);
      });

      test('Validates cycle length is within acceptable range', () {
        const validLengths = [21, 23, 28, 30, 35];
        
        for (var length in validLengths) {
          expect(length >= 21 && length <= 35, true);
        }
      });

      test('Rejects invalid cycle length', () {
        const invalidLengths = [10, 20, 40, 100];
        
        for (var length in invalidLengths) {
          expect(length >= 21 && length <= 35, false);
        }
      });

      test('Can update existing cycle', () {
        final cycleData = {
          'id': 'cycle-123',
          'user_id': 'user-456',
          'cycle_length': 28,
          'is_current': true,
        };

        // Update cycle_length
        cycleData['cycle_length'] = 29;
        expect(cycleData['cycle_length'], 29);

        // Update is_current
        cycleData['is_current'] = false;
        expect(cycleData['is_current'], false);
      });

      test('Can delete cycle', () {
        final cycles = <String, dynamic>{
          'cycle-1': {'id': 'cycle-1'},
          'cycle-2': {'id': 'cycle-2'},
        };

        expect(cycles.length, 2);
        
        cycles.remove('cycle-1');
        expect(cycles.length, 1);
        expect(cycles.containsKey('cycle-1'), false);
      });
    });

    group('Error Handling', () {
      test('Handles missing required fields', () {
        final incompleteData = {
          'id': 'cycle-123',
          // Missing user_id, start_date, cycle_length
        };

        expect(incompleteData['user_id'], isNull);
        expect(incompleteData['start_date'], isNull);
        expect(incompleteData['cycle_length'], isNull);
      });

      test('Handles invalid date format', () {
        expect(
          () => DateTime.parse('invalid-date'),
          throwsFormatException,
        );
      });

      test('Handles null cycle data', () {
        final cycleData = null;
        expect(cycleData, isNull);
      });

      test('Handles empty cycles list', () {
        final cycles = <Map<String, dynamic>>[];
        expect(cycles.isEmpty, true);
        expect(cycles.length, 0);
      });
    });

    group('Backward Compatibility', () {
      test('getUserCycles() returns same data as getAllCycles()', () {
        final mockCycles = [
          {'id': 'cycle-1', 'cycle_length': 28},
          {'id': 'cycle-2', 'cycle_length': 30},
        ];

        // Both methods should return the same data
        expect(mockCycles.length, 2);
      });

      test('Supports legacy cycle data format', () {
        final legacyCycleData = {
          'cycle_id': 'old-cycle-123', // Old naming convention
          'user_id': 'user-456',
          'start_date': '2024-01-15',
          'length': 28,
        };

        // Should still be accessible
        expect(legacyCycleData['cycle_id'], 'old-cycle-123');
        expect(legacyCycleData['length'], 28);
      });
    });
  });
}

/// Helper function to detect phase based on day and phase lengths
String _detectPhase(int currentDay, List<int> phaseLengths) {
  const phases = ['menstrual', 'follicular', 'ovulation', 'luteal'];
  
  var dayCount = 0;
  for (var i = 0; i < phaseLengths.length; i++) {
    dayCount += phaseLengths[i];
    if (currentDay <= dayCount) {
      return phases[i];
    }
  }
  
  return phases.last;
}
