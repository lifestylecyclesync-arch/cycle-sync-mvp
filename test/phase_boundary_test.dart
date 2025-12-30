import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/utils/cycle_utils.dart';

void main() {
  group('Phase Boundary Tests (Refined Formula)', () {
    // Test with 28-day cycle, menstrualLength=5, ovulationDay=14
    final lastPeriodStart = DateTime(2024, 1, 1); // Jan 1
    final cycleLength = 28;
    final menstrualLength = 5;

    test('Menstrual Phase: Days 1-5 (split into two parts)', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 1), menstrualLength: menstrualLength), 'Menstrual (Days 1 to ML-1)'); // Day 1 - ML-1
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 3), menstrualLength: menstrualLength), 'Menstrual (Days 1 to ML-1)'); // Day 3 - ML-1
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 5), menstrualLength: menstrualLength), 'Menstrual (Day ML)'); // Day 5 - ML
    });

    test('Follicular Phase: Days 6-12 (split into Early and Late)', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 6), menstrualLength: menstrualLength), 'Follicular (Early)'); // Day 6 - Power phase
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 10), menstrualLength: menstrualLength), 'Follicular (Early)'); // Day 10 - Power phase (ML+5)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 11), menstrualLength: menstrualLength), 'Follicular (Late)'); // Day 11 - Manifestation phase (ML+6)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 12), menstrualLength: menstrualLength), 'Follicular (Late)'); // Day 12 (OD-2) - Manifestation phase
    });

    test('Ovulation Phase: Days 13-15', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 13), menstrualLength: menstrualLength), 'Ovulation'); // Day 13 (OD-1)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 14), menstrualLength: menstrualLength), 'Ovulation'); // Day 14 (OD)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 15), menstrualLength: menstrualLength), 'Ovulation'); // Day 15 (OD+1)
    });

    test('Early Luteal Phase: Days 16-19', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 16), menstrualLength: menstrualLength), 'Early Luteal'); // Day 16 (OD+2)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 17), menstrualLength: menstrualLength), 'Early Luteal'); // Day 17 (OD+3)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 19), menstrualLength: menstrualLength), 'Early Luteal'); // Day 19 (OD+5)
    });

    test('Late Luteal Phase: Days 20-28', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 20), menstrualLength: menstrualLength), 'Luteal (Late)'); // Day 20 (OD+6)
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 25), menstrualLength: menstrualLength), 'Luteal (Late)'); // Day 25
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 28), menstrualLength: menstrualLength), 'Luteal (Late)'); // Day 28 (last day)
    });

    test('Cycle wraps correctly - Day 29 is Day 1 of next cycle', () {
      expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 29), menstrualLength: menstrualLength), 'Menstrual'); // Day 29 = Day 1 of next
    });

    group('26-day cycle tests', () {
      final cycleLength26 = 26;
      // OD = 26 - 14 = 12 (ovulationDay)
      // Follicular: Days 6-10 (ML+1 to OD-2)
      // Ovulation: Days 11-13 (OD-1 to OD+1)
      // Early Luteal: Days 14-17 (OD+2 to OD+5)
      // Luteal: Days 18-26
      test('26-day cycle boundaries: Follicular Days 6-10, OD Days 11-13, EL Days 14-17, LL Days 18-26', () {
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 6), menstrualLength: menstrualLength), 'Follicular (Early)'); // Day 6
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 10), menstrualLength: menstrualLength), 'Follicular (Early)'); // Day 10 (OD-2)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 11), menstrualLength: menstrualLength), 'Ovulation'); // Day 11 (OD-1)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 12), menstrualLength: menstrualLength), 'Ovulation'); // Day 12 (OD)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 13), menstrualLength: menstrualLength), 'Ovulation'); // Day 13 (OD+1)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 14), menstrualLength: menstrualLength), 'Early Luteal'); // Day 14 (OD+2)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 17), menstrualLength: menstrualLength), 'Early Luteal'); // Day 17 (OD+5)
        expect(getCyclePhase(lastPeriodStart, cycleLength26, DateTime(2024, 1, 18), menstrualLength: menstrualLength), 'Luteal (Late)'); // Day 18 (OD+6)
    });

    group('32-day cycle tests', () {
      final cycleLength32 = 32;
      // OD = 32 - 14 = 18 (ovulationDay)
      // Follicular: Days 6-16 (ML+1 to OD-2)
      // Ovulation: Days 17-19 (OD-1 to OD+1)
      // Early Luteal: Days 20-23 (OD+2 to OD+5)
      // Luteal: Days 24-32
      test('32-day cycle boundaries: Follicular Days 6-16, OD Days 17-19, EL Days 20-23, LL Days 24-32', () {
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 6), menstrualLength: menstrualLength), 'Follicular (Early)'); // Day 6
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 16), menstrualLength: menstrualLength), 'Follicular (Late)'); // Day 16 (OD-2)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 17), menstrualLength: menstrualLength), 'Ovulation'); // Day 17 (OD-1)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 18), menstrualLength: menstrualLength), 'Ovulation'); // Day 18 (OD)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 19), menstrualLength: menstrualLength), 'Ovulation'); // Day 19 (OD+1)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 20), menstrualLength: menstrualLength), 'Early Luteal'); // Day 20 (OD+2)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 23), menstrualLength: menstrualLength), 'Early Luteal'); // Day 23 (OD+5)
        expect(getCyclePhase(lastPeriodStart, cycleLength32, DateTime(2024, 1, 24), menstrualLength: menstrualLength), 'Luteal (Late)'); // Day 24 (OD+6)
      });
    });

    group('Variable menstrual length tests', () {
      test('7-day menstrual length: Menstrual Days 1-7', () {
        final ml7 = 7;
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 1), menstrualLength: ml7), 'Menstrual'); // Day 1
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 7), menstrualLength: ml7), 'Menstrual (Days 1 to ML-1)'); // Day 1
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 6), menstrualLength: ml7), 'Menstrual (Days 1 to ML-1)'); // Day 6 (ML-1)
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 7), menstrualLength: ml7), 'Menstrual (Day ML)'); // Day 7 (ML) // Day 8 (should be follicular, not menstrual)
      });

      test('3-day menstrual length: Menstrual Days 1-3', () {
        final ml3 = 3;
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 1), menstrualLength: ml3), 'Menstrual (Days 1 to ML-1)'); // Day 1
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 2), menstrualLength: ml3), 'Menstrual (Days 1 to ML-1)'); // Day 2 (ML-1)
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 3), menstrualLength: ml3), 'Menstrual (Day ML)'); // Day 3 (ML)
        expect(getCyclePhase(lastPeriodStart, cycleLength, DateTime(2024, 1, 4), menstrualLength: ml3), 'Follicular (Early)'); // Day 4
      });
    });
  });
}