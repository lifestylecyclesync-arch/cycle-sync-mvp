import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/models/phase.dart';
import 'package:cycle_sync_mvp/utils/cycle_utils.dart';

void main() {
  group('Phase Detection Tests', () {
    test('All 5 phases exist with correct names', () {
      expect(CyclePhases.phases.length, 5);
      expect(CyclePhases.phases[0].name, 'Menstrual');
      expect(CyclePhases.phases[1].name, 'Follicular');
      expect(CyclePhases.phases[2].name, 'Ovulation');
      expect(CyclePhases.phases[3].name, 'Early Luteal');
      expect(CyclePhases.phases[4].name, 'Luteal');
    });

    test('All phases have required properties', () {
      for (Phase phase in CyclePhases.phases) {
        expect(phase.name.isNotEmpty, true);
        expect(phase.emoji.isNotEmpty, true);
        expect(phase.description.isNotEmpty, true);
        expect(phase.hormonalBasis.isNotEmpty, true);
        expect(phase.workoutPhase.isNotEmpty, true);
        expect(phase.nutritionApproach.isNotEmpty, true);
        expect(phase.fastingDetails.isNotEmpty, true);
      }
    });

    test('Detect correct phase for day 1 (Menstrual)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime dayOne = DateTime(2025, 12, 15);

      String phase = getCyclePhase(lastPeriodStart, cycleLength, dayOne,
          menstrualLength: menstrualLength);

      expect(phase, 'Menstrual');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutName, 'Low-Impact Training');
    });

    test('Detect correct phase for day 7 (Follicular)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime dayNine = DateTime(2025, 12, 21); // Day 7 of cycle

      String phase = getCyclePhase(lastPeriodStart, cycleLength, dayNine,
          menstrualLength: menstrualLength);

      expect(phase, 'Follicular');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutName, 'Mid-Impact Training');
    });

    test('Detect correct phase for day 14 (Ovulation)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      DateTime day14 = DateTime(2025, 12, 28); // Day 14 of cycle

      String phase = getCyclePhase(lastPeriodStart, cycleLength, day14,
          menstrualLength: menstrualLength);

      expect(phase, 'Ovulation');
      
      Phase? phaseData = CyclePhases.findPhaseByName(phase);
      expect(phaseData?.workoutName, 'Strength Training');
    });

    test('5-day ovulation window (OD-2 to OD+2)', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      
      // OD = 14, so ovulation should be Days 12-16
      for (int day = 12; day <= 16; day++) {
        DateTime dateToCheck = lastPeriodStart.add(Duration(days: day - 1));
        String phase = getCyclePhase(lastPeriodStart, cycleLength, dateToCheck,
            menstrualLength: menstrualLength);
        expect(phase, 'Ovulation', 
            reason: 'Day $day should be Ovulation phase');
      }
    });

    test('Follicular phase ends before ovulation', () {
      DateTime lastPeriodStart = DateTime(2025, 12, 15);
      int cycleLength = 28;
      int menstrualLength = 5;
      
      // Day 11 should be Follicular, Day 12 should be Ovulation
      DateTime day11 = lastPeriodStart.add(Duration(days: 10));
      DateTime day12 = lastPeriodStart.add(Duration(days: 11));
      
      String phaseDay11 = getCyclePhase(lastPeriodStart, cycleLength, day11,
          menstrualLength: menstrualLength);
      String phaseDay12 = getCyclePhase(lastPeriodStart, cycleLength, day12,
          menstrualLength: menstrualLength);
      
      expect(phaseDay11, 'Follicular');
      expect(phaseDay12, 'Ovulation');
    });
  });
}
